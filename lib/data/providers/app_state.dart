import 'package:flutter/foundation.dart';
import '../local/database_helper.dart';
import '../models/contributor.dart';
import '../models/contributor_payment_status.dart';
import '../models/gift_disbursement.dart';
import '../models/monthly_period.dart';
import '../models/payment.dart';
import '../models/period_summary.dart';
import '../models/settings_model.dart';

class AppState extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  bool _isLoading = true;
  String? _errorMessage;

  MonthlyPeriod? _selectedPeriod;
  PeriodSummary? _currentSummary;
  List<Contributor> _contributors = [];
  List<ContributorPaymentStatus> _paymentStatuses = [];
  List<Payment> _periodPayments = [];
  List<GiftDisbursement> _periodGifts = [];
  List<MonthlyPeriod> _allPeriods = [];
  AppSettings? _settings;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  MonthlyPeriod? get selectedPeriod => _selectedPeriod;
  PeriodSummary? get currentSummary => _currentSummary;
  List<Contributor> get contributors => _contributors;
  List<ContributorPaymentStatus> get paymentStatuses => _paymentStatuses;
  List<Payment> get periodPayments => _periodPayments;
  List<GiftDisbursement> get periodGifts => _periodGifts;
  List<MonthlyPeriod> get allPeriods => _allPeriods;
  AppSettings? get settings => _settings;

  AppState() {
    init();
  }

  Future<void> init() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _db.seedSampleDataIfEmpty();
      _settings = await _db.getSettings();
      _allPeriods = await _db.getAllPeriods();

      final now = DateTime.now();
      final currentYearMonth =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // Select existing period or current month
      final initialPeriodStr = _allPeriods.isNotEmpty
          ? _allPeriods.first.yearMonth
          : currentYearMonth;

      await selectPeriod(initialPeriodStr);
      await loadContributors();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectPeriod(String yearMonth) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedPeriod = await _db.getOrCreatePeriod(yearMonth);
      _allPeriods = await _db.getAllPeriods();
      await _loadPeriodData();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadPeriodData() async {
    if (_selectedPeriod == null) return;
    final periodId = _selectedPeriod!.id;

    _currentSummary = await _db.getPeriodSummary(periodId);
    _paymentStatuses = await _db.getContributorStatusesForPeriod(periodId);
    _periodPayments = await _db.getPeriodPayments(periodId: periodId);
    _periodGifts = await _db.getPeriodGifts(periodId);
  }

  Future<void> refreshCurrentPeriod() async {
    if (_selectedPeriod == null) return;
    try {
      await _loadPeriodData();
      _allPeriods = await _db.getAllPeriods();
      await loadContributors();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadContributors({String? searchQuery, String? statusFilter}) async {
    try {
      _contributors = await _db.getContributors(
        searchQuery: searchQuery,
        statusFilter: statusFilter,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> goToPreviousMonth() async {
    if (_selectedPeriod == null) return;
    final ym = _selectedPeriod!.yearMonth;
    final parts = ym.split('-');
    var y = int.parse(parts[0]);
    var m = int.parse(parts[1]) - 1;
    if (m < 1) {
      m = 12;
      y -= 1;
    }
    final prevYm = '$y-${m.toString().padLeft(2, '0')}';
    await selectPeriod(prevYm);
  }

  Future<void> goToNextMonth() async {
    if (_selectedPeriod == null) return;
    final ym = _selectedPeriod!.yearMonth;
    final parts = ym.split('-');
    var y = int.parse(parts[0]);
    var m = int.parse(parts[1]) + 1;
    if (m > 12) {
      m = 1;
      y += 1;
    }
    final nextYm = '$y-${m.toString().padLeft(2, '0')}';
    await selectPeriod(nextYm);
  }

  Future<void> addContributor({
    required String name,
    String contributorType = 'person',
    String? phone,
    required String startsOn,
    String? endsOn,
    String? notes,
    required int initialRateIqd,
  }) async {
    await _db.addContributor(
      name: name,
      contributorType: contributorType,
      phone: phone,
      startsOn: startsOn,
      endsOn: endsOn,
      notes: notes,
      initialRateIqd: initialRateIqd,
    );
    await refreshCurrentPeriod();
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
    await _db.updateContributor(
      id: id,
      name: name,
      contributorType: contributorType,
      phone: phone,
      startsOn: startsOn,
      endsOn: endsOn,
      notes: notes,
    );
    await refreshCurrentPeriod();
  }

  Future<void> setContributorStatus(String id, String newStatus) async {
    await _db.setContributorStatus(id, newStatus);
    await refreshCurrentPeriod();
  }

  Future<void> updateContributorRate({
    required String contributorId,
    required int newAmountIqd,
    required String effectiveFrom,
  }) async {
    await _db.updateContributorRate(
      contributorId: contributorId,
      newAmountIqd: newAmountIqd,
      effectiveFrom: effectiveFrom,
    );
    await refreshCurrentPeriod();
  }

  Future<void> recordPayment({
    required String contributorId,
    required int amountIqd,
    required String method,
    required String paidAt,
    String? referenceNumber,
    String? notes,
  }) async {
    if (_selectedPeriod == null) throw StateError('لم يتم اختيار شهر');
    await _db.submitPayment(
      periodId: _selectedPeriod!.id,
      contributorId: contributorId,
      amountIqd: amountIqd,
      method: method,
      paidAt: paidAt,
      referenceNumber: referenceNumber,
      notes: notes,
    );
    await refreshCurrentPeriod();
  }

  Future<void> voidPayment({
    required String paymentId,
    required String voidReason,
  }) async {
    await _db.voidPayment(paymentId: paymentId, voidReason: voidReason);
    await refreshCurrentPeriod();
  }

  Future<void> recordGiftDisbursement({
    required int amountIqd,
    required String spentAt,
    required String recipientOrPurpose,
    String? notes,
  }) async {
    if (_selectedPeriod == null) throw StateError('لم يتم اختيار شهر');
    await _db.submitGiftDisbursement(
      periodId: _selectedPeriod!.id,
      amountIqd: amountIqd,
      spentAt: spentAt,
      recipientOrPurpose: recipientOrPurpose,
      notes: notes,
    );
    await refreshCurrentPeriod();
  }

  Future<void> voidGiftDisbursement({
    required String giftId,
    required String voidReason,
  }) async {
    await _db.voidGiftDisbursement(giftId: giftId, voidReason: voidReason);
    await refreshCurrentPeriod();
  }

  Future<void> updatePeriodTarget(int newTargetIqd, {String? reason}) async {
    if (_selectedPeriod == null) return;
    await _db.updatePeriodTarget(
      periodId: _selectedPeriod!.id,
      newTargetIqd: newTargetIqd,
      reason: reason,
    );
    _selectedPeriod = await _db.getOrCreatePeriod(_selectedPeriod!.yearMonth);
    await refreshCurrentPeriod();
  }

  Future<void> disburseSponsorship({
    required int amountIqd,
    required String disbursedAt,
    String? notes,
  }) async {
    if (_selectedPeriod == null) throw StateError('لم يتم اختيار شهر');
    await _db.disburseMonthSponsorship(
      periodId: _selectedPeriod!.id,
      disbursedAmountIqd: amountIqd,
      disbursedAt: disbursedAt,
      notes: notes,
    );
    _selectedPeriod = await _db.getOrCreatePeriod(_selectedPeriod!.yearMonth);
    await refreshCurrentPeriod();
  }

  Future<void> unlockCurrentPeriod({String? reason}) async {
    if (_selectedPeriod == null) throw StateError('لم يتم اختيار شهر');
    await _db.unlockPeriod(
      periodId: _selectedPeriod!.id,
      reason: reason,
    );
    _selectedPeriod = await _db.getOrCreatePeriod(_selectedPeriod!.yearMonth);
    await refreshCurrentPeriod();
  }

  Future<void> updateDefaultTarget(int newTarget) async {
    await _db.updateDefaultTarget(newTarget);
    _settings = await _db.getSettings();
    notifyListeners();
  }

  Future<void> resetAllData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _db.resetAllData();
      _settings = await _db.getSettings();
      _allPeriods = [];
      _contributors = [];
      _paymentStatuses = [];
      _periodPayments = [];
      _periodGifts = [];
      _currentSummary = null;

      final now = DateTime.now();
      final currentYearMonth =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';
      _selectedPeriod = await _db.getOrCreatePeriod(currentYearMonth);
      _allPeriods = await _db.getAllPeriods();
      await _loadPeriodData();
      await loadContributors();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
