class MonthlyObligation {
  final String id;
  final String periodId;
  final String contributorId;
  final int expectedAmountIqd;
  final String createdAt;

  const MonthlyObligation({
    required this.id,
    required this.periodId,
    required this.contributorId,
    required this.expectedAmountIqd,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'period_id': periodId,
      'contributor_id': contributorId,
      'expected_amount_iqd': expectedAmountIqd,
      'created_at': createdAt,
    };
  }

  factory MonthlyObligation.fromMap(Map<String, dynamic> map) {
    return MonthlyObligation(
      id: map['id'] as String,
      periodId: map['period_id'] as String,
      contributorId: map['contributor_id'] as String,
      expectedAmountIqd: (map['expected_amount_iqd'] as num).toInt(),
      createdAt: map['created_at'] as String,
    );
  }
}
