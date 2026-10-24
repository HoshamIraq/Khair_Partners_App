import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/local/database_helper.dart';
import '../../data/models/audit_log.dart';
import '../../data/providers/app_state.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  final AppState state;

  const SettingsScreen({super.key, required this.state});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<AuditLog> _logs = [];
  bool _isLoadingLogs = false;

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoadingLogs = true);
    final logs = await DatabaseHelper.instance.getAuditLogs(limit: 50);
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoadingLogs = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.state.settings;
    final defaultTarget = settings?.defaultTargetIqd ?? 200000;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإعدادات والتدقيق'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sponsorship Target Configuration
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen.withOpacity(0.12),
                  child: const Icon(Icons.monetization_on, color: AppTheme.primaryGreen),
                ),
                title: const Text(
                  'هدف الكفالة الافتراضي للشهور الجديدة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${CurrencyFormatter.formatIqd(defaultTarget)} (يسري على الشهور التي تُنشأ مستقبلاً)',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.edit, size: 20),
                onTap: () => _showEditDefaultTargetDialog(context, defaultTarget),
              ),
            ),

            const SizedBox(height: 12),

            // About App Option
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.secondaryGold.withOpacity(0.15),
                  child: const Icon(Icons.info_outline_rounded, color: AppTheme.secondaryGold),
                ),
                title: const Text(
                  'حول التطبيق',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Khair Partners • شركاء الخير • شركة الغري للحلول البرمجية',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // System Information Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.primaryGreen),
                        SizedBox(width: 8),
                        Text(
                          'معلومات النظام وقاعدة البيانات',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    Divider(height: 16),
                    Text('• قاعدة البيانات: SQLite محلي (Offline-first)', style: TextStyle(fontSize: 13)),
                    SizedBox(height: 4),
                    Text('• العملة: الدينار العراقي IQD (أعداد صحيحة)', style: TextStyle(fontSize: 13)),
                    SizedBox(height: 4),
                    Text('• الإصدار: 1.0 (MVP) — كفالة الأيتام', style: TextStyle(fontSize: 13)),
                    SizedBox(height: 4),
                    Text('• وضع الحفظ: معاملات ذرية (Transactions + Foreign Keys)', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Audit Logs Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'سجل التدقيق والعمليات (Audit Logs)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadAuditLogs,
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_isLoadingLogs)
              const Center(child: CircularProgressIndicator())
            else if (_logs.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('لا توجد سجلات تدقيق حتى الآن'),
                ),
              )
            else
              ..._logs.map((log) => _buildAuditCard(log)),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditCard(AuditLog log) {
    Color opColor;
    switch (log.operation) {
      case 'CREATE':
        opColor = AppTheme.targetReachedColor;
        break;
      case 'UPDATE':
        opColor = AppTheme.secondaryGold;
        break;
      case 'VOID':
      default:
        opColor = Colors.red;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: opColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            log.operation,
            style: TextStyle(color: opColor, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        title: Text(
          log.reason ?? log.entityType,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          'الكيان: ${log.entityType} • ${log.createdAt.split('T').first}',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ),
    );
  }

  void _showEditDefaultTargetDialog(BuildContext context, int currentTarget) {
    final controller = TextEditingController(text: currentTarget.toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تعديل الهدف الافتراضي العام'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'وفق متطلب FR-13: تعديل الهدف الافتراضي يسري فقط على الأشهر الجديدة المنشأة لاحقاً ولا يغير أهداف الشهور السابقة.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الهدف الافتراضي (د.ع) *',
                    suffixText: 'د.ع',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newTarget = CurrencyFormatter.parseIqd(controller.text);
                  if (newTarget != null && newTarget > 0) {
                    Navigator.of(ctx).pop();
                    await widget.state.updateDefaultTarget(newTarget);
                  }
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        );
      },
    );
  }
}
