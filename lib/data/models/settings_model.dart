class AppSettings {
  final int id;
  final int defaultTargetIqd;
  final String updatedAt;

  const AppSettings({
    required this.id,
    required this.defaultTargetIqd,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'default_target_iqd': defaultTargetIqd,
      'updated_at': updatedAt,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      id: (map['id'] as num).toInt(),
      defaultTargetIqd: (map['default_target_iqd'] as num).toInt(),
      updatedAt: map['updated_at'] as String,
    );
  }
}
