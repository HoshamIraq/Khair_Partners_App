import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/database_helper.dart';
import '../../data/models/audit_log.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  List<AuditLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    final logs = await DatabaseHelper.instance.getAuditLogs(limit: 200);
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  Color _getOperationColor(String op) {
    switch (op.toUpperCase()) {
      case 'CREATE':
      case 'PAYMENT':
        return const Color(0xFF2A9D8F); // Green
      case 'UPDATE':
        return AppTheme.yinMnBlue;
      case 'DISBURSE':
      case 'LOCK_AND_DISBURSE':
        return AppTheme.burntSienna;
      case 'UNLOCK':
        return const Color(0xFF3A506B);
      case 'VOID':
      case 'DELETE':
      case 'SYSTEM_RESET':
        return Colors.red.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  String _translateOperation(String op) {
    switch (op.toUpperCase()) {
      case 'CREATE':
        return 'إضافة جديدة';
      case 'UPDATE':
        return 'تعديل';
      case 'PAYMENT':
        return 'تسجيل دفعة';
      case 'DISBURSE':
      case 'LOCK_AND_DISBURSE':
        return 'تسديد وقفل';
      case 'UNLOCK':
        return 'إلغاء قفل الشهر';
      case 'VOID':
        return 'إلغاء';
      case 'DELETE':
        return 'حذف';
      case 'SYSTEM_RESET':
        return 'تصفير النظام';
      default:
        return op;
    }
  }

  String _translateEntity(String entity) {
    switch (entity.toLowerCase()) {
      case 'contributor':
      case 'contributors':
        return 'مساهم';
      case 'payment':
      case 'payments':
        return 'دفعة مالية';
      case 'monthly_period':
      case 'monthly_periods':
        return 'شهر مالي';
      case 'gift_disbursement':
      case 'gift_disbursements':
        return 'صندوق الهدايا';
      case 'system':
        return 'النظام';
      default:
        return entity;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFEFF7FA),
        appBar: AppBar(
          title: const Text('سجل التدقيق والعمليات'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث',
              onPressed: _fetchLogs,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _logs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'لا توجد عمليات مسجلة حتى الآن',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    itemBuilder: (ctx, i) {
                      final log = _logs[i];
                      final opColor = _getOperationColor(log.operation);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: opColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: opColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      _translateOperation(log.operation),
                                      style: TextStyle(
                                        color: opColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _translateEntity(log.entityType),
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    log.createdAt.length >= 16
                                        ? log.createdAt.substring(0, 16).replaceAll('T', ' ')
                                        : log.createdAt,
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                              if (log.reason != null && log.reason!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  log.reason!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.gunmetal,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              if (log.beforeJson != null || log.afterJson != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'المعرف: ${log.entityId}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
