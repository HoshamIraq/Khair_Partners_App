class ContributorPaymentStatus {
  final String contributorId;
  final String name;
  final String contributorType;
  final String? phone;
  final int expectedAmountIqd;
  final int paidIqd;
  final int remainingIqd;
  final String paymentStatus; // 'paid', 'partial', 'unpaid'
  final int paymentsCount;

  const ContributorPaymentStatus({
    required this.contributorId,
    required this.name,
    this.contributorType = 'person',
    this.phone,
    required this.expectedAmountIqd,
    required this.paidIqd,
    required this.remainingIqd,
    required this.paymentStatus,
    this.paymentsCount = 0,
  });

  bool get isPaid => paymentStatus == 'paid';
  bool get isPartial => paymentStatus == 'partial';
  bool get isUnpaid => paymentStatus == 'unpaid';

  String get statusArabicName {
    switch (paymentStatus) {
      case 'paid':
        return 'مسدد بالكامل';
      case 'partial':
        return 'مسدد جزئياً';
      case 'unpaid':
      default:
        return 'غير مسدد';
    }
  }

  factory ContributorPaymentStatus.fromMap(Map<String, dynamic> map) {
    return ContributorPaymentStatus(
      contributorId: map['contributor_id'] as String,
      name: map['name'] as String,
      contributorType: (map['contributor_type'] as String?) ?? 'person',
      phone: map['phone'] as String?,
      expectedAmountIqd: (map['expected_amount_iqd'] as num).toInt(),
      paidIqd: (map['paid_iqd'] as num).toInt(),
      remainingIqd: (map['remaining_iqd'] as num).toInt(),
      paymentStatus: map['payment_status'] as String,
      paymentsCount: map['payments_count'] != null
          ? (map['payments_count'] as num).toInt()
          : 0,
    );
  }
}
