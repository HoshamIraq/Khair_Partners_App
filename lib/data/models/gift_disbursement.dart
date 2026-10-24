class GiftDisbursement {
  final String id;
  final String periodId;
  final int amountIqd;
  final String spentAt; // ISO-8601
  final String recipientOrPurpose;
  final String? notes;
  final String status; // 'active', 'void'
  final String createdAt;

  const GiftDisbursement({
    required this.id,
    required this.periodId,
    required this.amountIqd,
    required this.spentAt,
    required this.recipientOrPurpose,
    this.notes,
    this.status = 'active',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'period_id': periodId,
      'amount_iqd': amountIqd,
      'spent_at': spentAt,
      'recipient_or_purpose': recipientOrPurpose,
      'notes': notes,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory GiftDisbursement.fromMap(Map<String, dynamic> map) {
    return GiftDisbursement(
      id: map['id'] as String,
      periodId: map['period_id'] as String,
      amountIqd: (map['amount_iqd'] as num).toInt(),
      spentAt: map['spent_at'] as String,
      recipientOrPurpose: map['recipient_or_purpose'] as String,
      notes: map['notes'] as String?,
      status: (map['status'] as String?) ?? 'active',
      createdAt: map['created_at'] as String,
    );
  }

  bool get isActive => status == 'active';
}
