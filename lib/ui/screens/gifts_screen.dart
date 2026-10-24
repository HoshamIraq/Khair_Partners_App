import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/gift_disbursement.dart';
import '../../data/providers/app_state.dart';

class GiftsScreen extends StatelessWidget {
  final AppState state;

  const GiftsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final period = state.selectedPeriod;
    final periodTitle = period?.arabicMonthName ?? '';
    final summary = state.currentSummary;
    final gifts = state.periodGifts;

    final unspentSurplus = summary?.unspentSurplus ?? 0;
    final canSpendGift = unspentSurplus > 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('سجل هدايا ومساعدات $periodTitle'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Surplus balance card (PRD Section 8)
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB45309), Color(0xFFD97706)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondaryGold.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.card_giftcard, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'الفائض المتاح لصرف الهدايا',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      CurrencyFormatter.formatIqd(unspentSurplus),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'إجمالي الفائض المحسوب: ${CurrencyFormatter.formatIqd(summary?.surplus ?? 0)} | المصروف: ${CurrencyFormatter.formatIqd(summary?.spentGifts ?? 0)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.secondaryGold,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: canSpendGift ? () => _showAddGiftDialog(context) : null,
                      icon: const Icon(Icons.add),
                      label: Text(
                        canSpendGift
                            ? 'تسجيل صرف هدية جديدة'
                            : 'لا يوجد فائض متاح للصرف في هذا الشهر',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'المصروفات المسجلة لهذا الشهر',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (gifts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'لم يتم تسجيل أي مصروفات هدايا في هذا الشهر حتى الآن',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...gifts.map((g) => _buildGiftCard(context, g)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGiftCard(BuildContext context, GiftDisbursement g) {
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
                  backgroundColor: AppTheme.secondaryGold.withOpacity(0.12),
                  child: const Icon(Icons.volunteer_activism, color: AppTheme.secondaryGold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.recipientOrPurpose,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: !g.isActive ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'تاريخ الصرف: ${g.spentAt.split('T').first}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatIqd(g.amountIqd),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: g.isActive ? AppTheme.secondaryGold : Colors.grey,
                        decoration: !g.isActive ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      g.isActive ? 'نشط' : 'ملغى',
                      style: TextStyle(
                        fontSize: 11,
                        color: g.isActive ? AppTheme.targetReachedColor : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (g.notes != null && g.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'ملاحظات: ${g.notes}',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
            if (g.isActive) ...[
              const Divider(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _showVoidGiftDialog(context, g),
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 16),
                  label: const Text('إلغاء الصرف', style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddGiftDialog(BuildContext context) {
    final amountCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime spentAt = DateTime.now();

    final maxSurplus = state.currentSummary?.unspentSurplus ?? 0;

    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تسجيل صرف هدية / مساعدة'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'الحد الأقصى المتاح للصرف: ${CurrencyFormatter.formatIqd(maxSurplus)}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.secondaryGold, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: purposeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'المستلم أو الغرض من الصرف *',
                      hintText: 'مثال: شراء ملابس عيد للأيتام',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'المبلغ (د.ع) *',
                      suffixText: 'د.ع',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات (اختياري)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final purpose = purposeCtrl.text.trim();
                  final amount = CurrencyFormatter.parseIqd(amountCtrl.text);

                  if (purpose.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى تحديد الغرض أو المستلم')),
                    );
                    return;
                  }

                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى إدخال مبلغ صحيح أكبر من صفر')),
                    );
                    return;
                  }

                  if (amount > maxSurplus) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('المبلغ يتجاوز الفائض المتاح (${CurrencyFormatter.formatIqd(maxSurplus)})')),
                    );
                    return;
                  }

                  Navigator.of(ctx).pop();
                  try {
                    await state.recordGiftDisbursement(
                      amountIqd: amount,
                      spentAt: spentAt.toIso8601String(),
                      recipientOrPurpose: purpose,
                      notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(backgroundColor: Colors.red, content: Text('$e')),
                      );
                    }
                  }
                },
                child: const Text('تأكيد الصرف'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVoidGiftDialog(BuildContext context, GiftDisbursement g) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إلغاء صرف الهدية'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('هل تريد إلغاء سجل صرف ${CurrencyFormatter.formatIqd(g.amountIqd)}؟'),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(labelText: 'سبب الإلغاء *'),
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
                  if (reason.isEmpty) return;
                  Navigator.of(ctx).pop();
                  await state.voidGiftDisbursement(giftId: g.id, voidReason: reason);
                },
                child: const Text('تأكيد الإلغاء'),
              ),
            ],
          ),
        );
      },
    );
  }
}
