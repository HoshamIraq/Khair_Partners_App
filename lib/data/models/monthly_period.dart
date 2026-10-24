class MonthlyPeriod {
  final String id;
  final String yearMonth; // YYYY-MM
  final int targetAmountIqd;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final bool isLocked;
  final int? disbursedAmountIqd;
  final String? disbursedAt;
  final String? disbursementNotes;

  const MonthlyPeriod({
    required this.id,
    required this.yearMonth,
    required this.targetAmountIqd,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isLocked = false,
    this.disbursedAmountIqd,
    this.disbursedAt,
    this.disbursementNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'year_month': yearMonth,
      'target_amount_iqd': targetAmountIqd,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_locked': isLocked ? 1 : 0,
      'disbursed_amount_iqd': disbursedAmountIqd,
      'disbursed_at': disbursedAt,
      'disbursement_notes': disbursementNotes,
    };
  }

  factory MonthlyPeriod.fromMap(Map<String, dynamic> map) {
    return MonthlyPeriod(
      id: map['id'] as String,
      yearMonth: map['year_month'] as String,
      targetAmountIqd: (map['target_amount_iqd'] as num).toInt(),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      isLocked: (map['is_locked'] as num?)?.toInt() == 1,
      disbursedAmountIqd: (map['disbursed_amount_iqd'] as num?)?.toInt(),
      disbursedAt: map['disbursed_at'] as String?,
      disbursementNotes: map['disbursement_notes'] as String?,
    );
  }

  MonthlyPeriod copyWith({
    String? id,
    String? yearMonth,
    int? targetAmountIqd,
    String? notes,
    String? createdAt,
    String? updatedAt,
    bool? isLocked,
    int? disbursedAmountIqd,
    String? disbursedAt,
    String? disbursementNotes,
  }) {
    return MonthlyPeriod(
      id: id ?? this.id,
      yearMonth: yearMonth ?? this.yearMonth,
      targetAmountIqd: targetAmountIqd ?? this.targetAmountIqd,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLocked: isLocked ?? this.isLocked,
      disbursedAmountIqd: disbursedAmountIqd ?? this.disbursedAmountIqd,
      disbursedAt: disbursedAt ?? this.disbursedAt,
      disbursementNotes: disbursementNotes ?? this.disbursementNotes,
    );
  }

  int get year => int.parse(yearMonth.substring(0, 4));
  int get month => int.parse(yearMonth.substring(5, 7));

  String get arabicMonthName {
    const months = [
      'كانون الثاني',
      'شباط',
      'آذار',
      'نيسان',
      'أيار',
      'حزيران',
      'تموز',
      'آب',
      'أيلول',
      'تشرين الأول',
      'تشرين الثاني',
      'كانون الأول',
    ];
    if (month >= 1 && month <= 12) {
      return '$month - ${months[month - 1]} $year';
    }
    return yearMonth;
  }
}
