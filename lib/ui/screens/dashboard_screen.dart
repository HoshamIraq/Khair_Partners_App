import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/payment.dart';
import '../../data/providers/app_state.dart';
import 'new_payment_dialog.dart';

class DashboardScreen extends StatelessWidget {
  final AppState state;
  final VoidCallback onNavigateToPayments;
  final VoidCallback onNavigateToStatuses;
  final VoidCallback onNavigateToGifts;

  const DashboardScreen({
    super.key,
    required this.state,
    required this.onNavigateToPayments,
    required this.onNavigateToStatuses,
    required this.onNavigateToGifts,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final period = state.selectedPeriod;
    final summary = state.currentSummary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('شركاء الخير — لوحة المؤشرات'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث البيانات',
              onPressed: () => state.refreshCurrentPeriod(),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => state.refreshCurrentPeriod(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Month / Year Navigator
                _buildMonthNavigator(context),

                const SizedBox(height: 16),

                // 2. Primary Sponsorship Target Card (PRD Section 8 & FR-09)
                if (summary != null) _buildTargetCard(context, summary),

                const SizedBox(height: 16),

                // 3. Cash vs Electronic Breakdown
                if (summary != null) _buildPaymentMethodsRow(context, summary),

                const SizedBox(height: 16),

                // 4. Contributor Status Counters
                if (summary != null) _buildStatusCounters(context, summary),

                const SizedBox(height: 16),

                // 5. Surplus & Gift Balance Card
                if (summary != null) _buildSurplusCard(context, summary),

                const SizedBox(height: 20),

                // 6. Quick Action Buttons
                _buildQuickActions(context),

                const SizedBox(height: 24),

                // 7. Recent Payments in this month
                _buildRecentPaymentsSection(context),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openNewPaymentDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('تسجيل دفعة'),
        ),
      ),
    );
  }

  Widget _buildMonthNavigator(BuildContext context) {
    final period = state.selectedPeriod;
    final title = period != null ? period.arabicMonthName : 'اختر الشهر';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'الشهر السابق',
              onPressed: () => state.goToPreviousMonth(),
            ),
            InkWell(
              onTap: () => _showMonthPicker(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: AppTheme.primaryGreen),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'الشهر القادم',
              onPressed: () => state.goToNextMonth(),
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthPicker(BuildContext context) {
    final currentPeriod = state.selectedPeriod;
    final year = currentPeriod != null ? currentPeriod.year : DateTime.now().year;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'اختيار شهر لسنة $year',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: List.generate(12, (index) {
                    final m = index + 1;
                    final ym = '$year-${m.toString().padLeft(2, '0')}';
                    final isSelected = currentPeriod?.yearMonth == ym;
                    const monthNames = [
                      '1 ك2', '2 شباط', '3 آذار', '4 نيسان',
                      '5 أيار', '6 حزيران', '7 تموز', '8 آب',
                      '9 أيلول', '10 ت1', '11 ت2', '12 ك1'
                    ];

                    return ChoiceChip(
                      label: Text(monthNames[index]),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryGreen,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) {
                        Navigator.of(ctx).pop();
                        state.selectPeriod(ym);
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTargetCard(BuildContext context, dynamic summary) {
    final isReached = summary.isTargetReached;
    final indicatorColor = isReached ? AppTheme.targetReachedColor : AppTheme.targetShortfallColor;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isReached
              ? [const Color(0xFF065F46), const Color(0xFF047857)]
              : [const Color(0xFF991B1B), const Color(0xFFB91C1C)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: indicatorColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isReached ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isReached ? 'تم تحقيق الهدف' : 'لم يتحقق الهدف بعد',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showEditTargetDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.edit, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'تعديل الهدف',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إجمالي المحصّل',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.formatIqd(summary.collectedTotal),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'المستهدف للكفالة',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.formatIqd(summary.targetIqd),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: summary.targetIqd > 0
                  ? (summary.collectedTotal / summary.targetIqd).clamp(0.0, 1.0)
                  : 0.0,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'نسبة الإنجاز: ${summary.progressPercent.toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                isReached
                    ? 'الفائض المحسوب: ${CurrencyFormatter.formatIqd(summary.surplus)}'
                    : 'النقص المتبقي: ${CurrencyFormatter.formatIqd(summary.shortfall)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsRow(BuildContext context, dynamic summary) {
    return Row(
      children: [
        // Cash Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cashColor.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.cashColor.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.cashColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.payments, color: AppTheme.cashColor, size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'المقبوضات النقدية',
                      style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  CurrencyFormatter.formatIqd(summary.cashTotal),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.cashColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Electronic Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.electronicColor.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.electronicColor.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.electronicColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.phone_android, color: AppTheme.electronicColor, size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'المقبوضات الإلكترونية',
                      style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  CurrencyFormatter.formatIqd(summary.electronicTotal),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.electronicColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCounters(BuildContext context, dynamic summary) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'حالات تسديد المساهمين',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: onNavigateToStatuses,
                  child: const Text('عرض التفاصيل'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Fully Paid
                Expanded(
                  child: InkWell(
                    onTap: onNavigateToStatuses,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.targetReachedColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.targetReachedColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            summary.fullyPaidCount.toString(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.targetReachedColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'مسدد بالكامل',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Partial
                Expanded(
                  child: InkWell(
                    onTap: onNavigateToStatuses,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryGold.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.secondaryGold.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            summary.partialPaidCount.toString(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondaryGold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'مسدد جزئياً',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Unpaid
                Expanded(
                  child: InkWell(
                    onTap: onNavigateToStatuses,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.targetShortfallColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.targetShortfallColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            summary.unpaidCount.toString(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.targetShortfallColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'غير مسدد',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurplusCard(BuildContext context, dynamic summary) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.card_giftcard, color: AppTheme.secondaryGold),
                    SizedBox(width: 8),
                    Text(
                      'الفائض والهدايا (القسم 8)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: onNavigateToGifts,
                  child: const Text('سجل الهدايا'),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الفائض المحسوب:'),
                Text(
                  CurrencyFormatter.formatIqd(summary.surplus),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الهدايا المصروفة فعلياً:'),
                Text(
                  CurrencyFormatter.formatIqd(summary.spentGifts),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الفائض المتاح غير المصروف:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  CurrencyFormatter.formatIqd(summary.unspentSurplus),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: summary.unspentSurplus > 0 ? AppTheme.targetReachedColor : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _openNewPaymentDialog(context),
            icon: const Icon(Icons.add_card),
            label: const Text('إدخال دفعة'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onNavigateToPayments,
            icon: const Icon(Icons.receipt_long),
            label: const Text('مدفوعات الشهر'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentPaymentsSection(BuildContext context) {
    final payments = state.periodPayments.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'آخر الدفعات المسجلة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (state.periodPayments.isNotEmpty)
              TextButton(
                onPressed: onNavigateToPayments,
                child: const Text('عرض الكل'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (payments.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'لا توجد دفعات مسجلة لهذا الشهر حتى الآن',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...payments.map((p) => _buildPaymentItem(p)),
      ],
    );
  }

  Widget _buildPaymentItem(Payment p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: p.isCash
              ? AppTheme.cashColor.withOpacity(0.15)
              : AppTheme.electronicColor.withOpacity(0.15),
          child: Icon(
            p.isCash ? Icons.payments : Icons.phone_android,
            color: p.isCash ? AppTheme.cashColor : AppTheme.electronicColor,
          ),
        ),
        title: Text(
          p.contributorName ?? 'مساهم',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: p.isVoid ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${p.methodArabicName} • ${p.paidAt.split('T').first}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.formatIqd(p.amountIqd),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: p.isVoid ? Colors.grey : AppTheme.targetReachedColor,
                decoration: p.isVoid ? TextDecoration.lineThrough : null,
              ),
            ),
            if (p.isVoid)
              const Text(
                'ملغاة',
                style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  void _openNewPaymentDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NewPaymentDialog(state: state),
    );
  }

  void _showEditTargetDialog(BuildContext context) {
    final period = state.selectedPeriod;
    if (period == null) return;
    final controller = TextEditingController(text: period.targetAmountIqd.toString());
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('تعديل هدف شهر ${period.arabicMonthName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ملاحظة: تعديل الهدف يغير نسبة التحصيل والفائض لهذا الشهر فقط، ولا يؤثر على الشهور الأخرى أو المبالغ المقبوضة.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الهدف الجديد (د.ع) *',
                    suffixText: 'د.ع',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'سبب التعديل (اختياري)',
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
                    await state.updatePeriodTarget(
                      newTarget,
                      reason: reasonController.text.trim().isNotEmpty
                          ? reasonController.text.trim()
                          : null,
                    );
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
