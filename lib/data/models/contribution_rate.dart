class ContributionRate {
  final String id;
  final String contributorId;
  final int amountIqd;
  final String effectiveFrom; // YYYY-MM-DD
  final String? effectiveUntil; // YYYY-MM-DD
  final String createdAt;

  const ContributionRate({
    required this.id,
    required this.contributorId,
    required this.amountIqd,
    required this.effectiveFrom,
    this.effectiveUntil,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contributor_id': contributorId,
      'amount_iqd': amountIqd,
      'effective_from': effectiveFrom,
      'effective_until': effectiveUntil,
      'created_at': createdAt,
    };
  }

  factory ContributionRate.fromMap(Map<String, dynamic> map) {
    return ContributionRate(
      id: map['id'] as String,
      contributorId: map['contributor_id'] as String,
      amountIqd: (map['amount_iqd'] as num).toInt(),
      effectiveFrom: map['effective_from'] as String,
      effectiveUntil: map['effective_until'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}
