import 'dart:math';

class PeriodSummary {
  final String periodId;
  final String yearMonth;
  final int targetIqd;
  final int cashTotal;
  final int electronicTotal;
  final int collectedTotal;
  final int coverageAmount;
  final int shortfall;
  final int surplus;
  final double progressPercent;
  final int spentGifts;
  final int unspentSurplus;
  final int fullyPaidCount;
  final int partialPaidCount;
  final int unpaidCount;
  final int totalObligatedCount;

  const PeriodSummary({
    required this.periodId,
    required this.yearMonth,
    required this.targetIqd,
    required this.cashTotal,
    required this.electronicTotal,
    required this.collectedTotal,
    required this.coverageAmount,
    required this.shortfall,
    required this.surplus,
    required this.progressPercent,
    required this.spentGifts,
    required this.unspentSurplus,
    required this.fullyPaidCount,
    required this.partialPaidCount,
    required this.unpaidCount,
    required this.totalObligatedCount,
  });

  bool get isTargetReached => collectedTotal >= targetIqd;

  factory PeriodSummary.calculate({
    required String periodId,
    required String yearMonth,
    required int targetIqd,
    required int cashTotal,
    required int electronicTotal,
    required int spentGifts,
    required int fullyPaidCount,
    required int partialPaidCount,
    required int unpaidCount,
  }) {
    final collected = cashTotal + electronicTotal;
    final coverage = min(collected, targetIqd);
    final shortfall = max(targetIqd - collected, 0);
    final surplus = max(collected - targetIqd, 0);
    final progress = targetIqd > 0 ? (collected * 100.0 / targetIqd) : 0.0;
    final unspentSurplus = surplus - spentGifts;
    final totalObligated = fullyPaidCount + partialPaidCount + unpaidCount;

    return PeriodSummary(
      periodId: periodId,
      yearMonth: yearMonth,
      targetIqd: targetIqd,
      cashTotal: cashTotal,
      electronicTotal: electronicTotal,
      collectedTotal: collected,
      coverageAmount: coverage,
      shortfall: shortfall,
      surplus: surplus,
      progressPercent: progress,
      spentGifts: spentGifts,
      unspentSurplus: unspentSurplus,
      fullyPaidCount: fullyPaidCount,
      partialPaidCount: partialPaidCount,
      unpaidCount: unpaidCount,
      totalObligatedCount: totalObligated,
    );
  }
}
