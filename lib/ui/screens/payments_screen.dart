import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/payment.dart';
import '../../data/providers/app_state.dart';
import 'new_payment_dialog.dart';

class PaymentsScreen extends StatefulWidget {
  final AppState state;

  const PaymentsScreen({super.key, required this.state});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  String _methodFilter = 'all'; // 'all', 'cash', 'electronic'
  String _statusFilter = 'all'; // 'all', 'active', 'void'

  @override
  Widget build(BuildContext context) {
    final period = widget.state.selectedPeriod;
    final periodTitle = period?.arabicMonthName ?? '';

    // Filter local payments list
    final payments = widget.state.periodPayments.where((p) {
      if (_methodFilter != 'all' && p.method != _methodFilter) return false;
      if (_statusFilter != 'all' && p.status != _statusFilter) return false;
      return true;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('مدفوعات $periodTitle'),
          actions: [
            IconButton(
              icon: Icon(period?.isLocked == true ? Icons.lock_outline : Icons.add),
              tooltip: period?.isLocked == true ? 'الشهر مقفل' : 'إضافة دفعة',
              onPressed: () {
                if (period?.isLocked == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppTheme.burntSienna,
                      content: Text('هذا الشهر مقفل وتم دفع كفالته مسبقاً، ولا يمكن إضافة دفعات جديدة إليه'),
                    ),
                  );
                } else {
                  _openNewPaymentDialog(context);
                }
              },
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEFF7FA),
        body: Column(
          children: [
            // Filter Bar with Dropdowns
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Payment Method Select
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F9FB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD6E4EB)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _methodFilter,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF3D5A80)),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('جميع الطرق', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                            DropdownMenuItem(value: 'cash', child: Text('نقدي فقط', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                            DropdownMenuItem(value: 'electronic', child: Text('إلكتروني فقط', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _methodFilter = val);
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Payment Status Select
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F9FB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD6E4EB)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _statusFilter,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF3D5A80)),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('جميع الحالات', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                            DropdownMenuItem(value: 'active', child: Text('نشطة فقط', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                            DropdownMenuItem(value: 'void', child: Text('ملغاة فقط', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _statusFilter = val);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Payments List
            Expanded(
              child: payments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'لا توجد دفعات مطابقة للشروط',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: payments.length,
                      itemBuilder: (ctx, i) => _buildPaymentCard(context, payments[i]),
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: null,
          onPressed: () => _openNewPaymentDialog(context),
          backgroundColor: AppTheme.burntSienna,
          foregroundColor: Colors.white,
          elevation: 5,
          shape: const CircleBorder(),
          tooltip: 'تسجيل دفعة',
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, Payment p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: p.isCash
                      ? AppTheme.cashColor.withOpacity(0.12)
                      : AppTheme.electronicColor.withOpacity(0.12),
                  child: Icon(
                    p.isCash ? Icons.payments : Icons.phone_android,
                    color: p.isCash ? AppTheme.cashColor : AppTheme.electronicColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.contributorName ?? 'مساهم',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: p.isVoid ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'تاريخ الدفع: ${p.paidAt.split('T').first}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatIqd(p.amountIqd),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: p.isVoid ? Colors.grey : AppTheme.targetReachedColor,
                        decoration: p.isVoid ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (p.isVoid ? Colors.red : AppTheme.primaryGreen).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        p.statusArabicName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: p.isVoid ? Colors.red : AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (p.referenceNumber != null && p.referenceNumber!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.tag, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'المرجع: ${p.referenceNumber}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],

            if (p.notes != null && p.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.notes, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'ملاحظة: ${p.notes}',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
            ],

            if (p.isVoid && p.voidReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'سبب الإلغاء: ${p.voidReason}',
                        style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (p.isActive) ...[
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showVoidDialog(context, p),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                    label: const Text('إبطال الدفعة', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showVoidDialog(BuildContext context, Payment p) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إبطال الدفعة (غير قابلة للحذف)'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سيتم إبطال دفعة ${CurrencyFormatter.formatIqd(p.amountIqd)} الخاصة بـ (${p.contributorName}).',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text(
                  'وفق قواعد النظام: لا يتم حذف الدفعة، بل يتم توثيق إبطالها وسبب الإلغاء في سجل التدقيق.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'سبب إبطال الدفعة *',
                    hintText: 'مثال: خطأ في إدخال المبلغ أو تم استرجاع الحوالة',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('تراجع'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  final reason = reasonCtrl.text.trim();
                  if (reason.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى كتابة سبب الإبطال')),
                    );
                    return;
                  }
                  Navigator.of(ctx).pop();
                  try {
                    await widget.state.voidPayment(paymentId: p.id, voidReason: reason);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.red,
                          content: Text('تم إبطال الدفعة وتسجيل التدقيق بنجاح'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(backgroundColor: Colors.black87, content: Text('$e')),
                      );
                    }
                  }
                },
                child: const Text('تأكيد الإبطال'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openNewPaymentDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NewPaymentDialog(state: widget.state),
    );
  }
}
