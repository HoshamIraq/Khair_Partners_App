import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/audit_log.dart';
import '../models/contributor.dart';
import '../models/contributor_payment_status.dart';
import '../models/gift_disbursement.dart';
import '../models/monthly_obligation.dart';
import '../models/monthly_period.dart';
import '../models/payment.dart';
import '../models/period_summary.dart';
import '../models/settings_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const _uuid = Uuid();

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('orphan_sponsorship.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final path = p.join(docsDir.path, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _createDB,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Contributors table
    await db.execute('''
      CREATE TABLE contributors (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        contributor_type TEXT NOT NULL DEFAULT 'person'
          CHECK (contributor_type IN ('person','department','group')),
        phone TEXT,
        starts_on TEXT NOT NULL,
        ends_on TEXT,
        status TEXT NOT NULL DEFAULT 'active'
          CHECK (status IN ('active','paused','archived')),
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        CHECK (ends_on IS NULL OR ends_on >= starts_on)
      );
    ''');

    // 2. Contribution Rates table
    await db.execute('''
      CREATE TABLE contribution_rates (
        id TEXT PRIMARY KEY,
        contributor_id TEXT NOT NULL REFERENCES contributors(id) ON DELETE RESTRICT,
        amount_iqd INTEGER NOT NULL CHECK (amount_iqd >= 0),
        effective_from TEXT NOT NULL,
        effective_until TEXT,
        created_at TEXT NOT NULL,
        CHECK (effective_until IS NULL OR effective_until >= effective_from)
      );
    ''');
    await db.execute('''
      CREATE INDEX idx_rates_contributor_dates ON contribution_rates(contributor_id, effective_from);
    ''');

    // 3. Settings table
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        default_target_iqd INTEGER NOT NULL CHECK (default_target_iqd > 0),
        updated_at TEXT NOT NULL
      );
    ''');

    // 4. Monthly Periods table
    await db.execute('''
      CREATE TABLE monthly_periods (
        id TEXT PRIMARY KEY,
        year_month TEXT NOT NULL UNIQUE
          CHECK (length(year_month)=7 AND substr(year_month,5,1)='-'
              AND CAST(substr(year_month,6,2) AS INTEGER) BETWEEN 1 AND 12),
        target_amount_iqd INTEGER NOT NULL CHECK (target_amount_iqd > 0),
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    // 5. Monthly Obligations table
    await db.execute('''
      CREATE TABLE monthly_obligations (
        id TEXT PRIMARY KEY,
        period_id TEXT NOT NULL REFERENCES monthly_periods(id) ON DELETE RESTRICT,
        contributor_id TEXT NOT NULL REFERENCES contributors(id) ON DELETE RESTRICT,
        expected_amount_iqd INTEGER NOT NULL CHECK (expected_amount_iqd >= 0),
        created_at TEXT NOT NULL,
        UNIQUE (period_id, contributor_id)
      );
    ''');
    await db.execute('''
      CREATE INDEX idx_obligations_period ON monthly_obligations(period_id);
    ''');

    // 6. Payments table
    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        period_id TEXT NOT NULL REFERENCES monthly_periods(id) ON DELETE RESTRICT,
        contributor_id TEXT NOT NULL REFERENCES contributors(id) ON DELETE RESTRICT,
        amount_iqd INTEGER NOT NULL CHECK (amount_iqd > 0),
        method TEXT NOT NULL CHECK (method IN ('cash','electronic')),
        paid_at TEXT NOT NULL,
        reference_number TEXT,
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','void')),
        void_reason TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        CHECK (status <> 'void' OR length(trim(coalesce(void_reason,''))) > 0)
      );
    ''');
    await db.execute('''
      CREATE INDEX idx_payments_period_status_method ON payments(period_id, status, method);
    ''');
    await db.execute('''
      CREATE INDEX idx_payments_contributor_period ON payments(contributor_id, period_id);
    ''');

    // 7. Gift Disbursements table
    await db.execute('''
      CREATE TABLE gift_disbursements (
        id TEXT PRIMARY KEY,
        period_id TEXT NOT NULL REFERENCES monthly_periods(id) ON DELETE RESTRICT,
        amount_iqd INTEGER NOT NULL CHECK (amount_iqd > 0),
        spent_at TEXT NOT NULL,
        recipient_or_purpose TEXT NOT NULL,
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','void')),
        created_at TEXT NOT NULL
      );
    ''');
    await db.execute('''
      CREATE INDEX idx_gifts_period_status ON gift_disbursements(period_id, status);
    ''');

    // 8. Audit Logs table
    await db.execute('''
      CREATE TABLE audit_logs (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        before_json TEXT,
        after_json TEXT,
        reason TEXT,
        created_at TEXT NOT NULL
      );
    ''');
    await db.execute('''
      CREATE INDEX idx_audit_entity ON audit_logs(entity_type, entity_id, created_at);
    ''');

    // Seed default settings row (default 200,000 IQD target)
    final now = DateTime.now().toIso8601String();
    await db.insert('settings', {
      'id': 1,
      'default_target_iqd': 200000,
      'updated_at': now,
    });
  }

  // ==========================================
  // SETTINGS
  // ==========================================
  Future<AppSettings> getSettings() async {
    final db = await database;
    final res = await db.query('settings', where: 'id = 1');
    if (res.isNotEmpty) {
      return AppSettings.fromMap(res.first);
    }
    // Fallback if empty
    final now = DateTime.now().toIso8601String();
    await db.insert('settings', {
      'id': 1,
      'default_target_iqd': 200000,
      'updated_at': now,
    });
    return AppSettings(id: 1, defaultTargetIqd: 200000, updatedAt: now);
  }

  Future<void> updateDefaultTarget(int newTarget) async {
    if (newTarget <= 0) {
      throw ArgumentError('يجب أن يكون الهدف مبلغاً موجباً أكبر من صفر');
    }
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'settings',
      {'default_target_iqd': newTarget, 'updated_at': now},
      where: 'id = 1',
    );
  }

  // ==========================================
  // CONTRIBUTORS & RATES
  // ==========================================
  Future<String> addContributor({
    required String name,
    String contributorType = 'person',
    String? phone,
    required String startsOn,
    String? endsOn,
    String? notes,
    required int initialRateIqd,
  }) async {
    if (initialRateIqd < 0) {
      throw ArgumentError('لا يمكن أن يكون مبلغ الالتزام سالباً');
    }
    if (endsOn != null && endsOn.compareTo(startsOn) < 0) {
      throw ArgumentError('تاريخ النهاية لا يمكن أن يكون قبل تاريخ البداية');
    }

    final db = await database;
    final now = DateTime.now().toIso8601String();
    final contributorId = _uuid.v4();
    final rateId = _uuid.v4();

    await db.transaction((txn) async {
      await txn.insert('contributors', {
        'id': contributorId,
        'name': name.trim(),
        'contributor_type': contributorType,
        'phone': phone?.trim(),
        'starts_on': startsOn,
        'ends_on': endsOn,
        'status': 'active',
        'notes': notes?.trim(),
        'created_at': now,
        'updated_at': now,
      });

      await txn.insert('contribution_rates', {
        'id': rateId,
        'contributor_id': contributorId,
        'amount_iqd': initialRateIqd,
        'effective_from': startsOn,
        'effective_until': null,
        'created_at': now,
      });

      await txn.insert('audit_logs', {
        'id': _uuid.v4(),
        'entity_type': 'contributors',
        'entity_id': contributorId,
        'operation': 'CREATE',
        'before_json': null,
        'after_json': jsonEncode({
          'name': name,
          'rate': initialRateIqd,
          'starts_on': startsOn,
        }),
        'reason': 'إضافة مساهم جديد',
        'created_at': now,
      });
    });

    return contributorId;
  }

  Future<void> updateContributor({
    required String id,
    required String name,
    required String contributorType,
    String? phone,
    required String startsOn,
    String? endsOn,
    String? notes,
  }) async {
    if (endsOn != null && endsOn.compareTo(startsOn) < 0) {
      throw ArgumentError('تاريخ النهاية لا يمكن أن يكون قبل تاريخ البداية');
    }
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final old = await getContributorById(id);
    if (old == null) throw StateError('المساهم غير موجود');

    await db.transaction((txn) async {
      await txn.update(
        'contributors',
        {
          'name': name.trim(),
          'contributor_type': contributorType,
          'phone': phone?.trim(),
          'starts_on': startsOn,
          'ends_on': endsOn,
          'notes': notes?.trim(),
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      await txn.insert('audit_logs', {
        'id': _uuid.v4(),
        'entity_type': 'contributors',
        'entity_id': id,
        'operation': 'UPDATE',
        'before_json': jsonEncode(old.toMap()),
        'after_json': jsonEncode({
          'name': name,
          'contributor_type': contributorType,
          'phone': phone,
          'starts_on': startsOn,
          'ends_on': endsOn,
          'notes': notes,
        }),
        'reason': 'تعديل بيانات المساهم',
        'created_at': now,
      });
    });
  }

  Future<void> setContributorStatus(String id, String newStatus) async {
    if (!['active', 'paused', 'archived'].contains(newStatus)) {
      throw ArgumentError('حالة غير صالحة');
    }
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final old = await getContributorById(id);
    if (old == null) throw StateError('المساهم غير موجود');

    await db.transaction((txn) async {
      await txn.update(
        'contributors',
        {'status': newStatus, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
      );

      await txn.insert('audit_logs', {
        'id': _uuid.v4(),
        'entity_type': 'contributors',
        'entity_id': id,
        'operation': 'UPDATE',
        'before_json': jsonEncode({'status': old.status}),
        'after_json': jsonEncode({'status': newStatus}),
        'reason': 'تغيير حالة المساهم إلى $newStatus',
        'created_at': now,
      });
    });
  }

  Future<void> updateContributorRate({
    required String contributorId,
    required int newAmountIqd,
    required String effectiveFrom, // YYYY-MM-DD
  }) async {
    if (newAmountIqd < 0) {
      throw ArgumentError('لا يمكن أن يكون مبلغ الالتزام سالباً');
    }
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      // Find open rate (effective_until IS NULL)
      final activeRates = await txn.query(
        'contribution_rates',
        where: 'contributor_id = ? AND effective_until IS NULL',
        orderBy: 'effective_from DESC',
      );

      if (activeRates.isNotEmpty) {
        final currentRate = activeRates.first;
        final currentFrom = currentRate['effective_from'] as String;
        if (effectiveFrom.compareTo(currentFrom) <= 0) {
          throw ArgumentError(
            'تاريخ نفاذ القيمة الجديدة ($effectiveFrom) يجب أن يكون بعد تاريخ القيمة السابقة ($currentFrom)',
          );
        }

        // Close current rate
        await txn.update(
          'contribution_rates',
          {'effective_until': effectiveFrom},
          where: 'id = ?',
          whereArgs: [currentRate['id']],
        );
      }

      // Insert new rate
      await txn.insert('contribution_rates', {
        'id': _uuid.v4(),
        'contributor_id': contributorId,
        'amount_iqd': newAmountIqd,
        'effective_from': effectiveFrom,
        'effective_until': null,
        'created_at': now,
      });

      await txn.insert('audit_logs', {
        'id': _uuid.v4(),
        'entity_type': 'contribution_rates',
        'entity_id': contributorId,
        'operation': 'UPDATE',
        'before_json': jsonEncode(activeRates.isNotEmpty ? activeRates.first : {}),
        'after_json': jsonEncode({
          'amount_iqd': newAmountIqd,
          'effective_from': effectiveFrom,
        }),
        'reason': 'تحديث قيمة الالتزام الشهري',
        'created_at': now,
      });
    });
  }

  Future<Contributor?> getContributorById(String id) async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT c.*,
        (
          SELECT cr.amount_iqd FROM contribution_rates cr
          WHERE cr.contributor_id = c.id
          ORDER BY cr.effective_from DESC LIMIT 1
        ) AS current_rate_amount
      FROM contributors c
      WHERE c.id = ?
    ''', [id]);

    if (res.isEmpty) return null;
    return Contributor.fromMap(res.first);
  }

  Future<List<Contributor>> getContributors({
    String? searchQuery,
    String? statusFilter,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('(c.name LIKE ? OR c.phone LIKE ?)');
      whereArgs.add('%${searchQuery.trim()}%');
      whereArgs.add('%${searchQuery.trim()}%');
    }

    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      whereClauses.add('c.status = ?');
      whereArgs.add(statusFilter);
    }

    final where = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

    final res = await db.rawQuery('''
      SELECT c.*,
        (
          SELECT cr.amount_iqd FROM contribution_rates cr
          WHERE cr.contributor_id = c.id
          ORDER BY cr.effective_from DESC LIMIT 1
        ) AS current_rate_amount
      FROM contributors c
      $where
      ORDER BY c.name ASC
    ''', whereArgs);

    return res.map((r) => Contributor.fromMap(r)).toList();
  }

  // ==========================================
  // MONTHLY PERIODS & OBLIGATIONS
  // ==========================================
  Future<MonthlyPeriod> getOrCreatePeriod(String yearMonth) async {
    // Validate yearMonth format: YYYY-MM
    final regex = RegExp(r'^\d{4}-(0[1-9]|1[0-2])$');
    if (!regex.hasMatch(yearMonth)) {
      throw ArgumentError('صيغة الشهر غير صالحة، يجب أن تكون YYYY-MM');
    }

    final db = await database;
    final existing = await db.query(
      'monthly_periods',
      where: 'year_month = ?',
      whereArgs: [yearMonth],
    );

    if (existing.isNotEmpty) {
      final period = MonthlyPeriod.fromMap(existing.first);
      // Ensure active contributors have obligations frozen for this month
      await _syncObligationsForPeriod(db, period);
      return period;
    }

    final settings = await getSettings();
    final now = DateTime.now().toIso8601String();
    final periodId = _uuid.v4();

    final newPeriod = MonthlyPeriod(
      id: periodId,
      yearMonth: yearMonth,
      targetAmountIqd: settings.defaultTargetIqd,
      notes: null,
      createdAt: now,
      updatedAt: now,
    );

    await db.transaction((txn) async {
      await txn.insert('monthly_periods', newPeriod.toMap());
      await _syncObligationsForPeriod(txn, newPeriod);
    });

    return newPeriod;
  }

  Future<void> _syncObligationsForPeriod(
    DatabaseExecutor db,
    MonthlyPeriod period,
  ) async {
    final yearMonth = period.yearMonth;
    final firstDayOfMonth = '$yearMonth-01';
    final parts = yearMonth.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final lastDayNum = DateTime(y, m + 1, 0).day;
    final lastDayOfMonth = '$yearMonth-${lastDayNum.toString().padLeft(2, '0')}';

    // Fetch active contributors valid for this month who don't have an obligation yet
    final candidates = await db.rawQuery('''
      SELECT c.id, c.starts_on,
        (
          SELECT cr.amount_iqd FROM contribution_rates cr
          WHERE cr.contributor_id = c.id
            AND cr.effective_from <= ?
          ORDER BY cr.effective_from DESC LIMIT 1
        ) AS rate_at_start_of_month,
        (
          SELECT cr.amount_iqd FROM contribution_rates cr
          WHERE cr.contributor_id = c.id
          ORDER BY cr.effective_from ASC LIMIT 1
        ) AS earliest_rate
      FROM contributors c
      WHERE c.status <> 'archived'
        AND c.starts_on <= ?
        AND (c.ends_on IS NULL OR c.ends_on >= ?)
        AND NOT EXISTS (
          SELECT 1 FROM monthly_obligations mo
          WHERE mo.period_id = ? AND mo.contributor_id = c.id
        )
    ''', [firstDayOfMonth, lastDayOfMonth, firstDayOfMonth, period.id]);

    final now = DateTime.now().toIso8601String();
    for (final row in candidates) {
      final contributorId = row['id'] as String;
      final rate = (row['rate_at_start_of_month'] as num?)?.toInt() ??
          (row['earliest_rate'] as num?)?.toInt() ??
          0;

      await db.insert(
        'monthly_obligations',
        {
          'id': _uuid.v4(),
          'period_id': period.id,
          'contributor_id': contributorId,
          'expected_amount_iqd': rate,
          'created_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> updatePeriodTarget({
    required String periodId,
    required int newTargetIqd,
    String? reason,
  }) async {
    if (newTargetIqd <= 0) {
      throw ArgumentError('يجب أن يكون الهدف مبلغاً موجباً أكبر من صفر');
    }
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final periodRes = await db.query('monthly_periods', where: 'id = ?', whereArgs: [periodId]);
    if (periodRes.isEmpty) throw StateError('الفترة غير موجودة');

    final oldPeriod = MonthlyPeriod.fromMap(periodRes.first);

    await db.transaction((txn) async {
      await txn.update(
        'monthly_periods',
        {'target_amount_iqd': newTargetIqd, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [periodId],
      );

      await txn.insert('audit_logs', {
        'id': _uuid.v4(),
        'entity_type': 'monthly_periods',
        'entity_id': periodId,
        'operation': 'UPDATE',
        'before_json': jsonEncode({'target_amount_iqd': oldPeriod.targetAmountIqd}),
        'after_json': jsonEncode({'target_amount_iqd': newTargetIqd}),
        'reason': reason ?? 'تعديل هدف الكفالة للشهر',
        'created_at': now,
      });
    });
  }

  Future<List<MonthlyPeriod>> getAllPeriods() async {
    final db = await database;
    final res = await db.query('monthly_periods', orderBy: 'year_month DESC');
    return res.map((r) => MonthlyPeriod.fromMap(r)).toList();
  }

  // ==========================================
  // PAYMENTS & AUDIT
  // ==========================================
  Future<String> submitPayment({
    required String periodId,
    required String contributorId,
    required int amountIqd,
    required String method, // 'cash', 'electronic'
    required String paidAt, // ISO-8601
    String? referenceNumber,
    String? notes,
  }) async {
    if (amountIqd <= 0) {
      throw ArgumentError('يجب أن يكون مبلغ الدفعة أكبر من صفر');
    }
    if (!['cash', 'electronic'].contains(method)) {
      throw ArgumentError('طريقة الدفع يجب أن تكون نقدي أو إلكتروني');
    }

    final db = await database;
    final paymentId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      // 1. Verify period exists
      final periodRes = await txn.query('monthly_periods', where: 'id = ?', whereArgs: [periodId]);
      if (periodRes.isEmpty) throw StateError('فترة الشهر غير موجودة');

      // 2. Ensure contributor has obligation in this period; if not, create obligation record
      final obRes = await txn.query(
        'monthly_obligations',
        where: 'period_id = ? AND contributor_id = ?',
        whereArgs: [periodId, contributorId],
      );

      if (obRes.isEmpty) {
        // Fetch contributor rate to create obligation
        final rateRes = await txn.rawQuery('''
          SELECT amount_iqd FROM contribution_rates
          WHERE contributor_id = ?
          ORDER BY effective_from DESC LIMIT 1
        ''', [contributorId]);
        final expectedRate = rateRes.isNotEmpty ? (rateRes.first['amount_iqd'] as num).toInt() : 0;

        await txn.insert('monthly_obligations', {
          'id': _uuid.v4(),
          'period_id': periodId,
          'contributor_id': contributorId,
          'expected_amount_iqd': expectedRate,
          'created_at': now,
        });
      }

      // 3. Insert payment
      await txn.insert('payments', {
        'id': paymentId,
        'period_id': periodId,
        'contributor_id': contributorId,
        'amount_iqd': amountIqd,
        'method': method,
        'paid_at': paidAt,
        'reference_number': referenceNumber?.trim(),
        'notes': notes?.trim(),
        'status': 'active',
        'void_reason': null,
        'created_at': now,
        'updated_at': now,
      });

      // 4. Insert audit log
      await txn.insert('audit_logs', {
        'id': _uuid.v4(),
        'entity_type': 'payments',
        'entity_id': paymentId,
        'operation': 'CREATE',
        'before_json': null,
        'after_json': jsonEncode({
          'period_id': periodId,
          'contributor_id': contributorId,
          'amount_iqd': amountIqd,
          'method': method,
          'paid_at': paidAt,
        }),
        'reason': 'تسجيل دفعة جديدة',
        'created_at': now,
      });
    });

    return paymentId;
  }

  Future<void> voidPayment({
    required String paymentId,
    required String voidReason,
  }) async {
    if (voidReason.trim().isEmpty) {
      throw ArgumentError('يجب ذكر سبب إبطال الدفعة لغايات التدقيق');
    }

    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      final pRes = await txn.query('payments', where: 'id = ?', whereArgs: [paymentId]);
      if (pRes.isEmpty) throw StateError('الدفعة غير موجودة');

      final payment = Payment.fromMap(pRes.first);
      if (payment.isVoid) throw StateError('هذه الدفعة ملغاة بالفعل');

      final periodId = payment.periodId;

      // Check gift disbursement consistency (Section 8: unspent_surplus cannot become negative)
      final periodRes = await txn.query('monthly_periods', where: 'id = ?', whereArgs: [periodId]);
      final target = (periodRes.first['target_amount_iqd'] as num).toInt();

      final activePaymentsRes = await txn.rawQuery('''
        SELECT COALESCE(SUM(amount_iqd), 0) as total
        FROM payments
        WHERE period_id = ? AND status = 'active'
      ''', [periodId]);
      final currentCollected = (activePaymentsRes.first['total'] as num).toInt();

      final activeGiftsRes = await txn.rawQuery('''
        SELECT COALESCE(SUM(amount_iqd), 0) as total
        FROM gift_disbursements
        WHERE period_id = ? AND status = 'active'
      ''', [periodId]);
      final spentGifts = (activeGiftsRes.first['total'] as num).toInt();

      final newCollected = currentCollected - payment.amountIqd;
      final newSurplus = max(newCollected - target, 0);

      if (spentGifts > newSurplus) {
        throw StateError(
          'لا يمكن إبطال الدفعة لأن خفض التحصيل سيجعل الفائض المتاح ($newSurplus د.ع) أقل من مصروفات الهدايا المسجلة في هذا الشهر ($spentGifts د.ع). يرجى معالجة مصروفات الهدايا أولاً.',
        );
      }

      // Mark payment as void
      await txn.update(
        'payments',
        {
          'status': 'void',
          'void_reason': voidReason.trim(),
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [paymentId],
      );

      // Audit log
      await txn.insert('audit_logs', {
        'id': _uuid.v4(),
        'entity_type': 'payments',
        'entity_id': paymentId,
        'operation': 'VOID',
        'before_json': jsonEncode(payment.toMap()),
        'after_json': jsonEncode({'status': 'void', 'void_reason': voidReason}),
        'reason': voidReason.trim(),
        'created_at': now,
      });
    });
  }

  Future<List<Payment>> getPeriodPayments({
    required String periodId,
    String? methodFilter,
    String? statusFilter,
    String? contributorIdFilter,
  }) async {
    final db = await database;
    final whereClauses = <String>['p.period_id = ?'];
    final whereArgs = <dynamic>[periodId];

    if (methodFilter != null && methodFilter.isNotEmpty && methodFilter != 'all') {
      whereClauses.add('p.method = ?');
      whereArgs.add(methodFilter);
    }

    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      whereClauses.add('p.status = ?');
      whereArgs.add(statusFilter);
    }

    if (contributorIdFilter != null && contributorIdFilter.isNotEmpty) {
      whereClauses.add('p.contributor_id = ?');
      whereArgs.add(contributorIdFilter);
    }

    final where = whereClauses.join(' AND ');

    final res = await db.rawQuery('''
      SELECT p.*, c.name AS contributor_name, mp.year_month AS period_year_month
      FROM payments p
      JOIN contributors c ON c.id = p.contributor_id
      JOIN monthly_periods mp ON mp.id = p.period_id
      WHERE $where
      ORDER BY p.paid_at DESC, p.created_at DESC
    ''', whereArgs);

    return res.map((r) => Payment.fromMap(r)).toList();
  }

  // ==========================================
  // GIFT DISBURSEMENTS
  // ==========================================
  Future<String> submitGiftDisbursement({
    required String periodId,
    required int amountIqd,
    required String spentAt,
    required String recipientOrPurpose,
    String? notes,
  }) async {
    if (amountIqd <= 0) {
      throw ArgumentError('يجب أن يكون مبلغ الهدية أكبر من صفر');
    }
    if (recipientOrPurpose.trim().isEmpty) {
      throw ArgumentError('يجب توثيق المستلم أو الغرض من الهدية');
    }

    final db = await database;
    final giftId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      // Calculate current unspent surplus for period
      final summary = await _calculatePeriodSummaryTxn(txn, periodId);
      if (amountIqd > summary.unspentSurplus) {
        throw StateError(
          'مبلغ الهدية المطلوبة (${amountIqd} د.ع) يتجاوز الفائض غير المصروف المتاح (${summary.unspentSurplus} د.ع).',
        );
      }

      await txn.insert('gift_disbursements', {
        'id': giftId,
        'period_id': periodId,
        'amount_iqd': amountIqd,
        'spent_at': spentAt,
        'recipient_or_purpose': recipientOrPurpose.trim(),
        'notes': notes?.trim(),
        'status': 'active',
        'created_at': now,
      });

      await txn.insert('audit_logs', {
        'id': _uuid.v4(),
        'entity_type': 'gift_disbursements',
        'entity_id': giftId,
        'operation': 'CREATE',
        'before_json': null,
        'after_json': jsonEncode({
          'period_id': periodId,
          'amount_iqd': amountIqd,
          'recipient': recipientOrPurpose,
        }),
        'reason': 'صرف هدية من الفائض',
        'created_at': now,
      });
    });

    return giftId;
  }

  Future<void> voidGiftDisbursement({
    required String giftId,
    required String voidReason,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      final gRes = await txn.query('gift_disbursements', where: 'id = ?', whereArgs: [giftId]);
      if (gRes.isEmpty) throw StateError('سجل الهدية غير موجود');

      await txn.update(
        'gift_disbursements',
        {'status': 'void'},
        where: 'id = ?',
        whereArgs: [giftId],
      );

      await txn.insert('audit_logs', {
        'id': _uuid.v4(),
        'entity_type': 'gift_disbursements',
        'entity_id': giftId,
        'operation': 'VOID',
        'before_json': jsonEncode(gRes.first),
        'after_json': jsonEncode({'status': 'void'}),
        'reason': voidReason,
        'created_at': now,
      });
    });
  }

  Future<List<GiftDisbursement>> getPeriodGifts(String periodId) async {
    final db = await database;
    final res = await db.query(
      'gift_disbursements',
      where: 'period_id = ?',
      whereArgs: [periodId],
      orderBy: 'spent_at DESC',
    );
    return res.map((r) => GiftDisbursement.fromMap(r)).toList();
  }

  // ==========================================
  // SUMMARIES & FINANCIAL CALCULATIONS (Section 8 & 13)
  // ==========================================
  Future<PeriodSummary> getPeriodSummary(String periodId) async {
    final db = await database;
    return await _calculatePeriodSummaryTxn(db, periodId);
  }

  Future<PeriodSummary> _calculatePeriodSummaryTxn(
    DatabaseExecutor db,
    String periodId,
  ) async {
    final periodRes = await db.query('monthly_periods', where: 'id = ?', whereArgs: [periodId]);
    if (periodRes.isEmpty) throw StateError('الفترة غير موجودة');

    final period = MonthlyPeriod.fromMap(periodRes.first);

    // Payments totals (Section 13)
    final paymentsSum = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN method='cash' THEN amount_iqd ELSE 0 END), 0) AS cash_total,
        COALESCE(SUM(CASE WHEN method='electronic' THEN amount_iqd ELSE 0 END), 0) AS electronic_total
      FROM payments
      WHERE period_id = ? AND status = 'active';
    ''', [periodId]);

    final cashTotal = (paymentsSum.first['cash_total'] as num).toInt();
    final electronicTotal = (paymentsSum.first['electronic_total'] as num).toInt();

    // Spent gifts total
    final giftsSum = await db.rawQuery('''
      SELECT COALESCE(SUM(amount_iqd), 0) AS gifts_total
      FROM gift_disbursements
      WHERE period_id = ? AND status = 'active';
    ''', [periodId]);
    final spentGifts = (giftsSum.first['gifts_total'] as num).toInt();

    // Contributor status counts (paid, partial, unpaid)
    final statuses = await _getContributorStatusesTxn(db, periodId);
    var fullyPaid = 0;
    var partialPaid = 0;
    var unpaid = 0;

    for (final s in statuses) {
      if (s.isPaid) fullyPaid++;
      if (s.isPartial) partialPaid++;
      if (s.isUnpaid) unpaid++;
    }

    return PeriodSummary.calculate(
      periodId: periodId,
      yearMonth: period.yearMonth,
      targetIqd: period.targetAmountIqd,
      cashTotal: cashTotal,
      electronicTotal: electronicTotal,
      spentGifts: spentGifts,
      fullyPaidCount: fullyPaid,
      partialPaidCount: partialPaid,
      unpaidCount: unpaid,
    );
  }

  Future<List<ContributorPaymentStatus>> getContributorStatusesForPeriod(
    String periodId,
  ) async {
    final db = await database;
    return await _getContributorStatusesTxn(db, periodId);
  }

  Future<List<ContributorPaymentStatus>> _getContributorStatusesTxn(
    DatabaseExecutor db,
    String periodId,
  ) async {
    // Exact SQL from PRD Section 13
    final res = await db.rawQuery('''
      WITH paid AS (
        SELECT contributor_id,
               SUM(amount_iqd) AS amount_paid,
               COUNT(id) AS payments_count
        FROM payments
        WHERE period_id = ? AND status = 'active'
        GROUP BY contributor_id
      )
      SELECT c.id AS contributor_id,
             c.name,
             c.contributor_type,
             c.phone,
             mo.expected_amount_iqd,
             COALESCE(p.amount_paid, 0) AS paid_iqd,
             MAX(mo.expected_amount_iqd - COALESCE(p.amount_paid, 0), 0) AS remaining_iqd,
             CASE
               WHEN COALESCE(p.amount_paid, 0) = 0 THEN 'unpaid'
               WHEN COALESCE(p.amount_paid, 0) >= mo.expected_amount_iqd THEN 'paid'
               ELSE 'partial'
             END AS payment_status,
             COALESCE(p.payments_count, 0) AS payments_count
      FROM monthly_obligations mo
      JOIN contributors c ON c.id = mo.contributor_id
      LEFT JOIN paid p ON p.contributor_id = mo.contributor_id
      WHERE mo.period_id = ?
      ORDER BY c.name ASC;
    ''', [periodId, periodId]);

    return res.map((r) => ContributorPaymentStatus.fromMap(r)).toList();
  }

  // Contributor history report across months (PRD Section 13)
  Future<List<Map<String, dynamic>>> getContributorHistory({
    required String contributorId,
    required String fromMonth,
    required String toMonth,
  }) async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT mp.year_month,
             mo.expected_amount_iqd,
             COALESCE(SUM(CASE WHEN p.status='active' AND p.method='cash' THEN p.amount_iqd ELSE 0 END), 0) AS cash_iqd,
             COALESCE(SUM(CASE WHEN p.status='active' AND p.method='electronic' THEN p.amount_iqd ELSE 0 END), 0) AS electronic_iqd,
             COALESCE(SUM(CASE WHEN p.status='active' THEN p.amount_iqd ELSE 0 END), 0) AS total_paid_iqd
      FROM monthly_obligations mo
      JOIN monthly_periods mp ON mp.id = mo.period_id
      LEFT JOIN payments p ON p.period_id = mo.period_id AND p.contributor_id = mo.contributor_id
      WHERE mo.contributor_id = ?
        AND mp.year_month BETWEEN ? AND ?
      GROUP BY mp.id, mp.year_month, mo.expected_amount_iqd
      ORDER BY mp.year_month ASC;
    ''', [contributorId, fromMonth, toMonth]);

    return res;
  }

  // Audit logs query
  Future<List<AuditLog>> getAuditLogs({int limit = 100}) async {
    final db = await database;
    final res = await db.query(
      'audit_logs',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return res.map((r) => AuditLog.fromMap(r)).toList();
  }

  // Seed sample data as documented in PRD section 5.1 & 5.2
  Future<void> seedSampleDataIfEmpty() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM contributors'),
    );
    if (count != null && count > 0) return;

    // Example Month 9 (PRD Section 5.1):
    // هشام: 20,000 إلكتروني
    // محمد نادر: 25,000 إلكتروني
    // المراقبة: 25,000 نقدي
    // الإدارية: 25,000 نقدي
    final now = DateTime.now();
    final yearMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final period = await getOrCreatePeriod(yearMonth);

    final c1 = await addContributor(
      name: 'هشام',
      contributorType: 'person',
      phone: '07800000001',
      startsOn: '$yearMonth-01',
      initialRateIqd: 20000,
    );
    final c2 = await addContributor(
      name: 'محمد نادر',
      contributorType: 'person',
      phone: '07800000002',
      startsOn: '$yearMonth-01',
      initialRateIqd: 25000,
    );
    final c3 = await addContributor(
      name: 'المراقبة',
      contributorType: 'department',
      startsOn: '$yearMonth-01',
      initialRateIqd: 25000,
    );
    final c4 = await addContributor(
      name: 'الإدارية',
      contributorType: 'department',
      startsOn: '$yearMonth-01',
      initialRateIqd: 25000,
    );

    // Refresh obligations
    await _syncObligationsForPeriod(db, period);

    // Insert payments
    await submitPayment(
      periodId: period.id,
      contributorId: c1,
      amountIqd: 20000,
      method: 'electronic',
      paidAt: DateTime.now().toIso8601String(),
      notes: 'حوالة زين كاش',
    );
    await submitPayment(
      periodId: period.id,
      contributorId: c2,
      amountIqd: 25000,
      method: 'electronic',
      paidAt: DateTime.now().toIso8601String(),
      notes: 'تحويل إلكتروني',
    );
    await submitPayment(
      periodId: period.id,
      contributorId: c3,
      amountIqd: 25000,
      method: 'cash',
      paidAt: DateTime.now().toIso8601String(),
      notes: 'تسليم يدوي في الصندوق',
    );
    await submitPayment(
      periodId: period.id,
      contributorId: c4,
      amountIqd: 25000,
      method: 'cash',
      paidAt: DateTime.now().toIso8601String(),
      notes: 'تسليم نقدي',
    );
  }
}
