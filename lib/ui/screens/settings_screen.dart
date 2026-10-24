import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/excel_exporter.dart';
import '../../data/providers/app_state.dart';
import 'about_screen.dart';
import 'audit_logs_screen.dart';

class SettingsScreen extends StatefulWidget {
  final AppState state;

  const SettingsScreen({super.key, required this.state});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final settings = widget.state.settings;
    final defaultTarget = settings?.defaultTargetIqd ?? 200000;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFEFF7FA),
        appBar: AppBar(
          title: const Text('الإعدادات'),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // 1. هدف الكفالة الافتراضية للشهور
            _buildSettingCard(
              icon: Icons.monetization_on_rounded,
              iconColor: AppTheme.yinMnBlue,
              title: 'هدف الكفالة الافتراضي للشهور',
              subtitle: '${CurrencyFormatter.formatIqd(defaultTarget)} (يسري على الشهور المنشأة مستقبلاً)',
              trailing: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.yinMnBlue),
              onTap: () => _showEditDefaultTargetDialog(context, defaultTarget),
            ),

            const SizedBox(height: 14),

            // 2. تصدير البيانات الى اكسل
            _buildSettingCard(
              icon: Icons.table_chart_rounded,
              iconColor: const Color(0xFF2A9D8F),
              title: 'تصدير البيانات إلى إكسل',
              subtitle: 'تصدير كافة السجلات، المساهمين، والمدفوعات بصيغة Excel (.xlsx)',
              trailing: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2A9D8F)),
                    )
                  : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: _isExporting ? null : () => _handleExportExcel(context),
            ),

            const SizedBox(height: 14),

            // 3. سجل التدقيق والعمليات (يحتوي على السجلات عند الضغط على الزر)
            _buildSettingCard(
              icon: Icons.history_rounded,
              iconColor: const Color(0xFF3D5A80),
              title: 'سجل التدقيق والعمليات',
              subtitle: 'عرض تفاصيل وسجل كافة العمليات والتعديلات السابقة في النظام',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AuditLogsScreen()),
                );
              },
            ),

            const SizedBox(height: 14),

            // 4. مسح بيانات التطبيق (تأكييد قبل المسح)
            _buildSettingCard(
              icon: Icons.delete_forever_rounded,
              iconColor: const Color(0xFFD90429),
              title: 'مسح بيانات التطبيق',
              subtitle: 'تصفير وحذف جميع المساهمين والمدفوعات والبدء من جديد',
              titleColor: const Color(0xFFD90429),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFD90429)),
              onTap: () => _showResetDataConfirmationDialog(context),
            ),

            const SizedBox(height: 14),

            // 5. حول التطبيق
            _buildSettingCard(
              icon: Icons.info_outline_rounded,
              iconColor: AppTheme.burntSienna,
              title: 'حول التطبيق',
              subtitle: 'Khair Partners • شركاء الخير • شركة الغري للحلول البرمجية',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback? onTap,
    Color? titleColor,
  }) {
    return Card(
      elevation: 0.8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: iconColor.withValues(alpha: 0.12),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: titleColor ?? AppTheme.gunmetal,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleExportExcel(BuildContext context) async {
    setState(() => _isExporting = true);
    try {
      await ExcelExporter.exportAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2A9D8F),
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'تم تصدير ملف الإكسل ومشاركته بنجاح!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('حدث خطأ أثناء تصدير الإكسل: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showResetDataConfirmationDialog(BuildContext context) {
    bool isConfirmed = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'تأكيد تصفير ومسح البيانات',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        'تحذير شديد: سيتم حذف جميع المساهمين، والمدفوعات، وسجلات الأشهر، وصندوق الهدايا، وسجل العمليات نهائياً! لا يمكن التراجع عن هذه الخطوة مطلقاً.',
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setDialogState(() {
                          isConfirmed = !isConfirmed;
                        });
                      },
                      child: Row(
                        children: [
                          Checkbox(
                            value: isConfirmed,
                            activeColor: Colors.red.shade700,
                            onChanged: (val) {
                              setDialogState(() {
                                isConfirmed = val ?? false;
                              });
                            },
                          ),
                          const Expanded(
                            child: Text(
                              'أفهم عواقب هذا الإجراء وأؤكد رغبتي بمسح كافة السجلات والبدء من جديد',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton.icon(
                    onPressed: isConfirmed
                        ? () async {
                            Navigator.of(ctx).pop();
                            await widget.state.resetAllData();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF2A9D8F),
                                  content: const Text(
                                    'تم تصفير ومسح كافة بيانات التطبيق بنجاح.',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          }
                        : null,
                    icon: const Icon(Icons.delete_forever, size: 20),
                    label: const Text('مسح وتصفير كل شيء'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade500,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('تعديل الهدف الافتراضي العام'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'تعديل الهدف الافتراضي يسري فقط على الأشهر الجديدة المنشأة لاحقاً ولا يغير أهداف الشهور السابقة.',
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
