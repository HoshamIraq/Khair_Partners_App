import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/contributor_payment_status.dart';
import '../../data/providers/app_state.dart';
import 'new_payment_dialog.dart';

class PaymentStatusesScreen extends StatefulWidget {
  final AppState state;

  const PaymentStatusesScreen({super.key, required this.state});

  @override
  State<PaymentStatusesScreen> createState() => _PaymentStatusesScreenState();
}

class _PaymentStatusesScreenState extends State<PaymentStatusesScreen> {
  String _filter = 'all'; // 'all', 'paid', 'partial', 'unpaid'
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final period = widget.state.selectedPeriod;
    final periodTitle = period?.arabicMonthName ?? '';

    final filtered = widget.state.paymentStatuses.where((s) {
      if (_filter != 'all' && s.paymentStatus != _filter) return false;
      if (_searchController.text.trim().isNotEmpty) {
        final query = _searchController.text.trim().toLowerCase();
        if (!s.name.toLowerCase().contains(query) &&
            !(s.phone?.contains(query) ?? false)) {
          return false;
        }
      }
      return true;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('كشف حالات تسديد $periodTitle'),
        ),
        body: Column(
          children: [
            // Search and status tabs
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'البحث باسم المساهم...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildChoiceChip('الكل (${widget.state.paymentStatuses.length})', 'all', Colors.black87),
                        const SizedBox(width: 8),
                        _buildChoiceChip(
                          'مسدد بالكامل (${widget.state.paymentStatuses.where((s) => s.isPaid).length})',
                          'paid',
                          AppTheme.targetReachedColor,
                        ),
                        const SizedBox(width: 8),
                        _buildChoiceChip(
                          'مسدد جزئياً (${widget.state.paymentStatuses.where((s) => s.isPartial).length})',
                          'partial',
                          AppTheme.secondaryGold,
                        ),
                        const SizedBox(width: 8),
                        _buildChoiceChip(
                          'غير مسدد (${widget.state.paymentStatuses.where((s) => s.isUnpaid).length})',
                          'unpaid',
                          AppTheme.targetShortfallColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'لا توجد سجلات مطابقة لهذا الفلتر',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => _buildStatusCard(context, filtered[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, String value, Color activeColor) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: activeColor.withOpacity(0.18),
      labelStyle: TextStyle(
        color: isSelected ? activeColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? activeColor : Colors.grey.shade300,
      ),
      onSelected: (_) => setState(() => _filter = value),
    );
  }

  Widget _buildStatusCard(BuildContext context, ContributorPaymentStatus s) {
    Color badgeColor;
    IconData badgeIcon;
    switch (s.paymentStatus) {
      case 'paid':
        badgeColor = AppTheme.targetReachedColor;
        badgeIcon = Icons.check_circle;
        break;
      case 'partial':
        badgeColor = AppTheme.secondaryGold;
        badgeIcon = Icons.timelapse;
        break;
      case 'unpaid':
      default:
        badgeColor = AppTheme.targetShortfallColor;
        badgeIcon = Icons.cancel;
        break;
    }

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
                  backgroundColor: badgeColor.withOpacity(0.12),
                  child: Icon(badgeIcon, color: badgeColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${s.phone ?? ''} ${s.paymentsCount > 0 ? '• عدد الدفعات: ${s.paymentsCount}' : ''}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    s.statusArabicName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('الالتزام المتوقع', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatIqd(s.expectedAmountIqd),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('المسدد', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatIqd(s.paidIqd),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: s.paidIqd > 0 ? AppTheme.targetReachedColor : Colors.grey,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('المتبقي', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatIqd(s.remainingIqd),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: s.remainingIqd > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (!s.isPaid) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => _openNewPaymentForContributor(context, s.contributorId),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('تسجيل دفعة لهذا المساهم'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openNewPaymentForContributor(BuildContext context, String contributorId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NewPaymentDialog(
        state: widget.state,
        preselectedContributorId: contributorId,
      ),
    );
  }
}
