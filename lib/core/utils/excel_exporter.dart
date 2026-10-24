import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/local/database_helper.dart';
import '../../data/models/monthly_period.dart';
import '../../data/models/period_summary.dart';

class ExcelExporter {
  static Future<String> exportAllData() async {
    final db = DatabaseHelper.instance;

    final contributors = await db.getContributorsForExport();
    final payments = await db.getPaymentsForExport();
    final periodsData = await db.getPeriodsForExport();
    final gifts = await db.getGiftsForExport();
    final auditLogs = await db.getAuditLogs(limit: 5000);

    final excel = Excel.createExcel();

    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString('#3D5A80'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // ==========================================
    // 1. المساهمون
    // ==========================================
    final sheetContributors = excel['المساهمون'];
    final headersC = [
      'ت',
      'اسم المساهم',
      'نوع المساهم',
      'رقم الهاتف',
      'الالتزام الشهري (د.ع)',
      'تاريخ البدء',
      'تاريخ الانتهاء',
      'الحالة',
      'ملاحظات',
      'تاريخ الإنشاء',
    ];

    sheetContributors.appendRow(headersC.map((h) => TextCellValue(h)).toList());
    for (int col = 0; col < headersC.length; col++) {
      sheetContributors.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0)).cellStyle = headerStyle;
    }

    for (int i = 0; i < contributors.length; i++) {
      final c = contributors[i];
      final typeStr = c['contributor_type'] == 'person'
          ? 'فرد'
          : c['contributor_type'] == 'department'
              ? 'قسم'
              : 'مجموعة';
      final statusStr = c['status'] == 'active'
          ? 'نشط'
          : c['status'] == 'paused'
              ? 'متوقف مؤقتاً'
              : 'مؤرشف';
      final rate = (c['current_rate_iqd'] as num?)?.toInt() ?? 0;

      sheetContributors.appendRow([
        IntCellValue(i + 1),
        TextCellValue(c['name']?.toString() ?? ''),
        TextCellValue(typeStr),
        TextCellValue(c['phone']?.toString() ?? '-'),
        IntCellValue(rate),
        TextCellValue(c['starts_on']?.toString() ?? ''),
        TextCellValue(c['ends_on']?.toString() ?? '-'),
        TextCellValue(statusStr),
        TextCellValue(c['notes']?.toString() ?? ''),
        TextCellValue(c['created_at']?.toString() ?? ''),
      ]);
    }

    // ==========================================
    // 2. سجل المدفوعات
    // ==========================================
    final sheetPayments = excel['سجل المدفوعات'];
    final headersP = [
      'ت',
      'اسم المساهم',
      'الشهر المالي',
      'المبلغ المدفوع (د.ع)',
      'طريقة الدفع',
      'تاريخ وتوقيت الدفع',
      'رقم الوصل / المرجع',
      'حالة الدفعة',
      'سبب الإلغاء',
      'ملاحظات',
    ];

    sheetPayments.appendRow(headersP.map((h) => TextCellValue(h)).toList());
    for (int col = 0; col < headersP.length; col++) {
      sheetPayments.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0)).cellStyle = headerStyle;
    }

    for (int i = 0; i < payments.length; i++) {
      final pRow = payments[i];
      final methodStr = pRow['method'] == 'cash' ? 'نقدي' : 'إلكتروني';
      final statusStr = pRow['status'] == 'active' ? 'نشطة' : 'ملغاة';
      final amount = (pRow['amount_iqd'] as num?)?.toInt() ?? 0;

      sheetPayments.appendRow([
        IntCellValue(i + 1),
        TextCellValue(pRow['contributor_name']?.toString() ?? ''),
        TextCellValue(pRow['year_month']?.toString() ?? ''),
        IntCellValue(amount),
        TextCellValue(methodStr),
        TextCellValue(pRow['paid_at']?.toString() ?? ''),
        TextCellValue(pRow['reference_number']?.toString() ?? '-'),
        TextCellValue(statusStr),
        TextCellValue(pRow['void_reason']?.toString() ?? ''),
        TextCellValue(pRow['notes']?.toString() ?? ''),
      ]);
    }

    // ==========================================
    // 3. الأشهر والكفالات
    // ==========================================
    final sheetPeriods = excel['الأشهر والكفالات'];
    final headersM = [
      'ت',
      'الشهر',
      'اسم الشهر بالعربية',
      'المستهدف (د.ع)',
      'المحصل الإجمالي (د.ع)',
      'المحصل النقدي (د.ع)',
      'المحصل الإلكتروني (د.ع)',
      'نسبة الإنجاز',
      'حالة الشهر',
      'مبلغ الكفالة المصروف (د.ع)',
      'تاريخ صرف الكفالة',
      'ملاحظات الصرف',
    ];

    sheetPeriods.appendRow(headersM.map((h) => TextCellValue(h)).toList());
    for (int col = 0; col < headersM.length; col++) {
      sheetPeriods.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0)).cellStyle = headerStyle;
    }

    for (int i = 0; i < periodsData.length; i++) {
      final item = periodsData[i];
      final period = item['period'] as MonthlyPeriod;
      final summary = item['summary'] as PeriodSummary;

      sheetPeriods.appendRow([
        IntCellValue(i + 1),
        TextCellValue(period.yearMonth),
        TextCellValue(period.arabicMonthName),
        IntCellValue(period.targetAmountIqd),
        IntCellValue(summary.collectedTotal),
        IntCellValue(summary.cashTotal),
        IntCellValue(summary.electronicTotal),
        TextCellValue('${summary.progressPercent.toStringAsFixed(1)}%'),
        TextCellValue(period.isLocked ? 'مقفول ومصروف' : 'مفتوح قيد التحصيل'),
        IntCellValue(period.disbursedAmountIqd ?? (period.isLocked ? summary.collectedTotal : 0)),
        TextCellValue(period.disbursedAt ?? '-'),
        TextCellValue(period.disbursementNotes ?? ''),
      ]);
    }

    // ==========================================
    // 4. صندوق الهدايا والمساعدات
    // ==========================================
    final sheetGifts = excel['صندوق الهدايا والفائض'];
    final headersG = [
      'ت',
      'الشهر',
      'المبلغ المصروف (د.ع)',
      'الجهة المستفيدة / الغرض',
      'تاريخ الصرف',
      'حالة الصرف',
      'ملاحظات',
    ];

    sheetGifts.appendRow(headersG.map((h) => TextCellValue(h)).toList());
    for (int col = 0; col < headersG.length; col++) {
      sheetGifts.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0)).cellStyle = headerStyle;
    }

    for (int i = 0; i < gifts.length; i++) {
      final g = gifts[i];
      final statusStr = g['status'] == 'active' ? 'نشط' : 'ملغى';
      final amount = (g['amount_iqd'] as num?)?.toInt() ?? 0;

      sheetGifts.appendRow([
        IntCellValue(i + 1),
        TextCellValue(g['year_month']?.toString() ?? ''),
        IntCellValue(amount),
        TextCellValue(g['recipient_or_purpose']?.toString() ?? ''),
        TextCellValue(g['spent_at']?.toString() ?? ''),
        TextCellValue(statusStr),
        TextCellValue(g['notes']?.toString() ?? ''),
      ]);
    }

    // ==========================================
    // 5. سجل التدقيق والعمليات
    // ==========================================
    final sheetAudit = excel['سجل التدقيق والعمليات'];
    final headersA = [
      'ت',
      'نوع العملية',
      'نوع الكيان',
      'معرف الكيان',
      'السبب / التفاصيل',
      'تاريخ وتوقيت العملية',
    ];

    sheetAudit.appendRow(headersA.map((h) => TextCellValue(h)).toList());
    for (int col = 0; col < headersA.length; col++) {
      sheetAudit.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0)).cellStyle = headerStyle;
    }

    for (int i = 0; i < auditLogs.length; i++) {
      final a = auditLogs[i];
      sheetAudit.appendRow([
        IntCellValue(i + 1),
        TextCellValue(a.operation),
        TextCellValue(a.entityType),
        TextCellValue(a.entityId),
        TextCellValue(a.reason ?? '-'),
        TextCellValue(a.createdAt),
      ]);
    }

    // Delete default Sheet1 if exists
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }
    excel.setDefaultSheet('المساهمون');

    // Save Excel file to storage
    final outputDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'تقرير_بيانات_شركاء_الخير_$timestamp.xlsx';
    final filePath = p.join(outputDir.path, fileName);

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('فشل تشفير ملف الإكسل');
    }

    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    // Share / Open with user
    // ignore: deprecated_member_use
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'تقرير بيانات منظومة شركاء الخير',
      text: 'تصدير كامل لبيانات منظومة شركاء الخير (كفالة الأيتام)',
    );

    return filePath;
  }
}
