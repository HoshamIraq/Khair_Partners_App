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
              icon: const Icon(Icons.add),
              tooltip: 'إضافة دفعة',
              onPressed: () => _openNewPaymentDialog(context),
            ),
          ],
        ),
        body: Column(
          children: [
            // Filter Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text('الطريقة: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        ChoiceChip(
                          label: const Text('الكل'),
                          selected: _methodFilter == 'all',
                          onSelected: (_) => setState(() => _methodFilter = 'all'),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('نقدي'),
                          selected: _methodFilter == 'cash',
                          selectedColor: AppTheme.cashColor,
                          labelStyle: TextStyle(
                            color: _methodFilter == 'cash' ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) => setState(() => _methodFilter = 'cash'),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('إلكتروني'),
                          selected: _methodFilter == 'electronic',
                          selectedColor: AppTheme.electronicColor,
                          labelStyle: TextStyle(
                            color: _methodFilter == 'electronic' ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) => setState(() => _methodFilter = 'electronic'),
                        ),
                        const SizedBox(width: 16),
                        const Text('الحالة: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        ChoiceChip(
                          label: const Text('الكل'),
                          selected: _statusFilter == 'all',
                          onSelected: (_) => setState(() => _statusFilter = 'all'),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('نشطة'),
                          selected: _statusFilter == 'active',
                          onSelected: (_) => setState(() => _statusFilter = 'active'),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('ملغاة'),
                          selected: _statusFilter == 'void',
                          selectedColor: Colors.red,
                          labelStyle: TextStyle(
                            color: _statusFilter == 'void' ? Colors.white : Colors.black87,
                          ),
                          onSelected: (_) => setState(() => _statusFilter = 'void'),
                        ),
                      ],
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openNewPaymentDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('تسجيل دفعة'),
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
