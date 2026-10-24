class Payment {
  final String id;
  final String periodId;
  final String contributorId;
  final int amountIqd;
  final String method; // 'cash', 'electronic'
  final String paidAt; // ISO-8601
  final String? referenceNumber;
  final String? notes;
  final String status; // 'active', 'void'
  final String? voidReason;
  final String createdAt;
  final String updatedAt;

  // Joined fields for display
  final String? contributorName;
  final String? periodYearMonth;

  const Payment({
    required this.id,
    required this.periodId,
    required this.contributorId,
    required this.amountIqd,
    required this.method,
    required this.paidAt,
    this.referenceNumber,
    this.notes,
    this.status = 'active',
    this.voidReason,
    required this.createdAt,
    required this.updatedAt,
    this.contributorName,
    this.periodYearMonth,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'period_id': periodId,
      'contributor_id': contributorId,
      'amount_iqd': amountIqd,
      'method': method,
      'paid_at': paidAt,
      'reference_number': referenceNumber,
      'notes': notes,
      'status': status,
      'void_reason': voidReason,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      periodId: map['period_id'] as String,
      contributorId: map['contributor_id'] as String,
      amountIqd: (map['amount_iqd'] as num).toInt(),
      method: map['method'] as String,
      paidAt: map['paid_at'] as String,
      referenceNumber: map['reference_number'] as String?,
      notes: map['notes'] as String?,
      status: (map['status'] as String?) ?? 'active',
      voidReason: map['void_reason'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      contributorName: map['contributor_name'] as String?,
      periodYearMonth: map['period_year_month'] as String?,
    );
  }

  bool get isCash => method == 'cash';
  bool get isElectronic => method == 'electronic';
  bool get isActive => status == 'active';
  bool get isVoid => status == 'void';

  String get methodArabicName => isCash ? 'نقدي' : 'إلكتروني';
  String get statusArabicName => isActive ? 'نشطة' : 'ملغاة';
}
