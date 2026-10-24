import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/local/database_helper.dart';
import '../../data/models/contributor.dart';

class ContributorHistoryScreen extends StatefulWidget {
  final Contributor contributor;

  const ContributorHistoryScreen({super.key, required this.contributor});

  @override
  State<ContributorHistoryScreen> createState() => _ContributorHistoryScreenState();
}

class _ContributorHistoryScreenState extends State<ContributorHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _history = [];
  int _totalPaid = 0;
  int _totalExpected = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    // From 1 year ago to current year
    final fromMonth = '${now.year - 1}-01';
    final toMonth = '${now.year}-12';

    final res = await DatabaseHelper.instance.getContributorHistory(
      contributorId: widget.contributor.id,
      fromMonth: fromMonth,
      toMonth: toMonth,
    );

    var paidSum = 0;
    var expectedSum = 0;
    for (final row in res) {
      paidSum += (row['total_paid_iqd'] as num).toInt();
      expectedSum += (row['expected_amount_iqd'] as num).toInt();
    }

    if (mounted) {
      setState(() {
        _history = res;
        _totalPaid = paidSum;
        _totalExpected = expectedSum;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.contributor;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('سجل مساهمات: ${c.name}'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Summary card
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: AppTheme.primaryGreen,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              c.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'النوع: ${c.typeArabicName} ${c.phone != null ? '• ${c.phone}' : ''}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const Divider(color: Colors.white24, height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text('إجمالي الالتزامات', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyFormatter.formatIqd(_totalExpected),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text('إجمالي المسدد', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text(
                                      CurrencyFormatter.formatIqd(_totalPaid),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      'التفصيل عبر الأشهر (وفق Section 13)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    if (_history.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text('لا توجد التزامات مسجلة لهذا المساهم في هذا النطاق'),
                        ),
                      )
                    else
                      ..._history.map((row) => _buildMonthHistoryRow(row)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMonthHistoryRow(Map<String, dynamic> row) {
    final ym = row['year_month'] as String;
    final expected = (row['expected_amount_iqd'] as num).toInt();
    final cash = (row['cash_iqd'] as num).toInt();
    final electronic = (row['electronic_iqd'] as num).toInt();
    final total = (row['total_paid_iqd'] as num).toInt();

    final isFullyPaid = total >= expected;
    final isUnpaid = total == 0;

    Color badgeColor;
    String badgeText;
    if (isFullyPaid) {
      badgeColor = AppTheme.targetReachedColor;
      badgeText = 'مسدد بالكامل';
    } else if (isUnpaid) {
      badgeColor = AppTheme.targetShortfallColor;
      badgeText = 'غير مسدد';
    } else {
      badgeColor = AppTheme.secondaryGold;
      badgeText = 'جزئي';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ym,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الالتزام: ${CurrencyFormatter.formatIqd(expected)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('نقدي: ${CurrencyFormatter.formatIqd(cash)}', style: const TextStyle(fontSize: 12, color: AppTheme.cashColor)),
                Text('إلكتروني: ${CurrencyFormatter.formatIqd(electronic)}', style: const TextStyle(fontSize: 12, color: AppTheme.electronicColor)),
                Text(
                  'المجموع: ${CurrencyFormatter.formatIqd(total)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isFullyPaid ? AppTheme.targetReachedColor : Colors.black87),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
