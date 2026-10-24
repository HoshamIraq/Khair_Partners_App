class AuditLog {
  final String id;
  final String entityType;
  final String entityId;
  final String operation; // 'CREATE', 'UPDATE', 'VOID'
  final String? beforeJson;
  final String? afterJson;
  final String? reason;
  final String createdAt;

  const AuditLog({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    this.beforeJson,
    this.afterJson,
    this.reason,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation,
      'before_json': beforeJson,
      'after_json': afterJson,
      'reason': reason,
      'created_at': createdAt,
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'] as String,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String,
      operation: map['operation'] as String,
      beforeJson: map['before_json'] as String?,
      afterJson: map['after_json'] as String?,
      reason: map['reason'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}
