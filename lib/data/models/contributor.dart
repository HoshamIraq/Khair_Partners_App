class Contributor {
  final String id;
  final String name;
  final String contributorType; // 'person', 'department', 'group'
  final String? phone;
  final String startsOn; // YYYY-MM-DD
  final String? endsOn; // YYYY-MM-DD
  final String status; // 'active', 'paused', 'archived'
  final String? notes;
  final String createdAt;
  final String updatedAt;

  // Additional helper field when joining with current rate
  final int? currentRateAmount;

  const Contributor({
    required this.id,
    required this.name,
    this.contributorType = 'person',
    this.phone,
    required this.startsOn,
    this.endsOn,
    this.status = 'active',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.currentRateAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contributor_type': contributorType,
      'phone': phone,
      'starts_on': startsOn,
      'ends_on': endsOn,
      'status': status,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Contributor.fromMap(Map<String, dynamic> map) {
    return Contributor(
      id: map['id'] as String,
      name: map['name'] as String,
      contributorType: (map['contributor_type'] as String?) ?? 'person',
      phone: map['phone'] as String?,
      startsOn: map['starts_on'] as String,
      endsOn: map['ends_on'] as String?,
      status: (map['status'] as String?) ?? 'active',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      currentRateAmount: map['current_rate_amount'] != null
          ? (map['current_rate_amount'] as num).toInt()
          : null,
    );
  }

  Contributor copyWith({
    String? id,
    String? name,
    String? contributorType,
    String? phone,
    String? startsOn,
    String? endsOn,
    String? status,
    String? notes,
    String? createdAt,
    String? updatedAt,
    int? currentRateAmount,
  }) {
    return Contributor(
      id: id ?? this.id,
      name: name ?? this.name,
      contributorType: contributorType ?? this.contributorType,
      phone: phone ?? this.phone,
      startsOn: startsOn ?? this.startsOn,
      endsOn: endsOn ?? this.endsOn,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentRateAmount: currentRateAmount ?? this.currentRateAmount,
    );
  }

  String get typeArabicName {
    switch (contributorType) {
      case 'department':
        return 'قسم';
      case 'group':
        return 'مجموعة';
      case 'person':
      default:
        return 'فرد';
    }
  }

  String get statusArabicName {
    switch (status) {
      case 'paused':
        return 'متوقف مؤقتاً';
      case 'archived':
        return 'مؤرشف';
      case 'active':
      default:
        return 'نشط';
    }
  }
}
