import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/payment.dart';
import '../../data/providers/app_state.dart';
import '../widgets/brand_logo.dart';
import '../widgets/wavy_background.dart';
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

    final summary = state.currentSummary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFEFF7FA),
        floatingActionButton: FloatingActionButton(
          heroTag: null,
          onPressed: () => _handleOpenNewPayment(context),
          backgroundColor: AppTheme.burntSienna,
          foregroundColor: Colors.white,
          elevation: 5,
          shape: const CircleBorder(),
          tooltip: 'إدخال دفعة',
          child: const Icon(Icons.add, size: 28),
        ),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: BrandLogo(size: 34)),
          ),
          title: const Text(
            'شركاء الخير — لوحة المؤشرات',
            style: TextStyle(
              color: Color(0xFF293241),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            // Icon button for 'إدخال دفعة' (Record Payment)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Center(
                child: Tooltip(
                  message: 'إدخال دفعة',
                  child: InkWell(
                    onTap: () => _handleOpenNewPayment(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCEEF6),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFC7E2ED), width: 0.8),
                      ),
                      child: const Icon(
                        Icons.add_card_rounded,
                        color: Color(0xFF3D5A80),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Refresh Button
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Center(
                child: Tooltip(
                  message: 'تحديث البيانات',
                  child: InkWell(
                    onTap: () => state.refreshCurrentPeriod(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCEEF6),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFC7E2ED), width: 0.8),
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: Color(0xFF293241),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: WavyBackground(
          child: RefreshIndicator(
            onRefresh: () => state.refreshCurrentPeriod(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Month / Year Navigator
                  _buildMonthNavigator(context),

                  const SizedBox(height: 14),

                  // 2. Primary Sponsorship Target Card (Slideable & Long-Press Lockable)
                  if (summary != null) _buildTargetCard(context, summary),

                  const SizedBox(height: 14),

                  // 3. Cash vs Electronic Breakdown
                  if (summary != null) _buildPaymentMethodsRow(context, summary),

                  const SizedBox(height: 14),

                  // 4. Contributor Status Counters
                  if (summary != null) _buildStatusCounters(context, summary),

                  const SizedBox(height: 14),

                  // 5. Surplus & Gift Balance Card
                  if (summary != null) _buildSurplusCard(context, summary),

                  const SizedBox(height: 16),

                  // 6. Recent Payments in this month
                  _buildRecentPaymentsSection(context),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. Month Navigator ---
  Widget _buildMonthNavigator(BuildContext context) {
    final period = state.selectedPeriod;
    final title = period != null ? period.arabicMonthName : 'اختر الشهر';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD8EBF2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF293241).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Next Month Button (Left arrow in RTL)
          InkWell(
            onTap: () => state.goToNextMonth(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFE2F1F7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_left,
                color: Color(0xFF3D5A80),
                size: 22,
              ),
            ),
          ),

          // Center Month Title
          InkWell(
            onTap: () => _showMonthPicker(context),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF293241),
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF293241),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2F1F7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_month,
                      color: Color(0xFF3D5A80),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Previous Month Button (Right arrow in RTL)
          InkWell(
            onTap: () => state.goToPreviousMonth(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFE2F1F7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right,
                color: Color(0xFF3D5A80),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMonthPicker(BuildContext context) {
    final currentPeriod = state.selectedPeriod;
    int selectedYear = currentPeriod != null ? currentPeriod.year : DateTime.now().year;
    bool isYearSelectionMode = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final now = DateTime.now();

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Drag Indicator Handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Title Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2F1F7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.calendar_month_rounded,
                                color: Color(0xFF3D5A80),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'اختيار الشهر والسنة',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF293241),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close, color: Colors.grey),
                          tooltip: 'إغلاق',
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Year Selection & Step Controls
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F6FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD8EBF2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left Year Arrow (points outward to the left: <)
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: Color(0xFF3D5A80), size: 26),
                            tooltip: 'السنة السابقة',
                            onPressed: () {
                              setModalState(() {
                                selectedYear -= 1;
                              });
                            },
                          ),

                          // Interactive Year Pill (toggles year list / grid)
                          InkWell(
                            onTap: () {
                              setModalState(() {
                                isYearSelectionMode = !isYearSelectionMode;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isYearSelectionMode ? AppTheme.yinMnBlue : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isYearSelectionMode ? AppTheme.yinMnBlue : const Color(0xFFB5D7E8),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'سنة $selectedYear',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: isYearSelectionMode ? Colors.white : const Color(0xFF293241),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    isYearSelectionMode ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                    color: isYearSelectionMode ? Colors.white : const Color(0xFF3D5A80),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Right Year Arrow (points outward to the right: >)
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: Color(0xFF3D5A80), size: 26),
                            tooltip: 'السنة التالية',
                            onPressed: () {
                              setModalState(() {
                                selectedYear += 1;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick Jump to Current Year
                    if (selectedYear != now.year) ...[
                      Align(
                        alignment: Alignment.center,
                        child: TextButton.icon(
                          onPressed: () {
                            setModalState(() {
                              selectedYear = now.year;
                              isYearSelectionMode = false;
                            });
                          },
                          icon: const Icon(Icons.today, size: 16, color: AppTheme.burntSienna),
                          label: Text(
                            'العودة إلى السنة الحالية (${now.year})',
                            style: const TextStyle(
                              color: AppTheme.burntSienna,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Direct Year Selection Grid (when user taps the Year Pill)
                    if (isYearSelectionMode) ...[
                      const Text(
                        'اختر السنة من القائمة:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D5A80),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 220,
                        child: GridView.builder(
                          itemCount: 16,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 2.0,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemBuilder: (ctx, i) {
                            final y = 2020 + i;
                            final isCurYear = y == selectedYear;
                            return InkWell(
                              onTap: () {
                                setModalState(() {
                                  selectedYear = y;
                                  isYearSelectionMode = false;
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isCurYear ? AppTheme.yinMnBlue : const Color(0xFFF4F8FA),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isCurYear ? AppTheme.yinMnBlue : const Color(0xFFD8EBF2),
                                  ),
                                ),
                                child: Text(
                                  '$y',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isCurYear ? FontWeight.bold : FontWeight.w600,
                                    color: isCurYear ? Colors.white : const Color(0xFF293241),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      // Month Grid for the selected year
                      const Text(
                        'اختر الشهر المطلوب:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D5A80),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: List.generate(12, (index) {
                          final m = index + 1;
                          final ym = '$selectedYear-${m.toString().padLeft(2, '0')}';
                          final isSelected = currentPeriod?.yearMonth == ym;
                          const monthNames = [
                            '1 - كانون الثاني',
                            '2 - شباط',
                            '3 - آذار',
                            '4 - نيسان',
                            '5 - أيار',
                            '6 - حزيران',
                            '7 - تموز',
                            '8 - آب',
                            '9 - أيلول',
                            '10 - تشرين الأول',
                            '11 - تشرين الثاني',
                            '12 - كانون الأول'
                          ];

                          return SizedBox(
                            width: (MediaQuery.of(ctx).size.width - 60) / 2,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(ctx).pop();
                                state.selectPeriod(ym);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.yinMnBlue : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.yinMnBlue : const Color(0xFFD8EBF2),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? AppTheme.yinMnBlue.withValues(alpha: 0.25)
                                          : Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      monthNames[index],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : const Color(0xFF293241),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- 2. Target Card (Slideable by swipe & lockable by long-press) ---
  Widget _buildTargetCard(BuildContext context, dynamic summary) {
    final period = state.selectedPeriod;
    final isLocked = period?.isLocked ?? false;
    final isReached = summary.isTargetReached;

    // Card background gradient:
    // When locked: Royal Deep Slate / Navy with gold-white accents
    // When reached: Dark gunmetal & deep blue
    // When not reached: Terracotta Orange
    final gradientColors = isLocked
        ? [const Color(0xFF1B324B), const Color(0xFF2D557F)]
        : (isReached
            ? [const Color(0xFF293241), AppTheme.yinMnBlue]
            : [const Color(0xFFE85D3F), const Color(0xFFCF482B)]);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        // In Arabic RTL:
        // Swiping towards left (velocity < -150) moves forward to next month
        // Swiping towards right (velocity > 150) moves backward to previous month
        if (details.primaryVelocity! < -150) {
          state.goToNextMonth();
        } else if (details.primaryVelocity! > 150) {
          state.goToPreviousMonth();
        }
      },
      onLongPress: () => _showDisburseSponsorshipDialog(context),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (isLocked
                      ? const Color(0xFF1B324B)
                      : (isReached ? AppTheme.yinMnBlue : const Color(0xFFE85D3F)))
                  .withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Watermark Bullseye
            Positioned(
              right: -20,
              top: -20,
              child: CustomPaint(
                size: const Size(160, 160),
                painter: _TargetBullseyePainter(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Row: Status pill tag + Edit / Lock button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Right: Target Status Tag or Locked Badge (Tappable & Long-Pressable)
                      InkWell(
                        onTap: () => _showDisburseSponsorshipDialog(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: isLocked
                                ? const Color(0xFF2A9D8F).withValues(alpha: 0.85)
                                : Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isLocked
                                    ? Icons.lock_rounded
                                    : (isReached ? Icons.check_circle : Icons.warning_amber_rounded),
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isLocked
                                    ? 'تم دفع الكفالة وقفل الشهر 🔒'
                                    : (isReached ? 'تم تحقيق الهدف' : 'لم يتحقق الهدف بعد'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Left: Edit Target Pill Button (disabled when locked)
                      if (!isLocked)
                        InkWell(
                          onTap: () => _showEditTargetDialog(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit, color: Colors.white, size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'تعديل الهدف',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        InkWell(
                          onTap: () => _showDisburseSponsorshipDialog(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'تفاصيل الكفالة',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Middle Row: Dual Metrics Columns with Vertical Divider
                  Row(
                    children: [
                      // Right Column: إجمالي المحصل (أو مبلغ الكفالة المصروف)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.savings_outlined, color: Colors.white70, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  isLocked ? 'الكفالة المصروفة' : 'إجمالي المحصل',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isLocked && period?.disbursedAmountIqd != null
                                  ? CurrencyFormatter.formatIqd(period!.disbursedAmountIqd!)
                                  : CurrencyFormatter.formatIqd(summary.collectedTotal),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Center Divider Line
                      Container(
                        height: 44,
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: Colors.white.withValues(alpha: 0.22),
                      ),

                      // Left Column: المستهدف للكفالة
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.flag_outlined, color: Colors.white70, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'المستهدف للكفالة',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.formatIqd(summary.targetIqd),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Progress Bar with Percentage Pill Tag
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: isLocked
                                ? 1.0
                                : (summary.targetIqd > 0
                                    ? (summary.collectedTotal / summary.targetIqd).clamp(0.0, 1.0)
                                    : 0.0),
                            backgroundColor: Colors.white.withValues(alpha: 0.25),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isLocked ? const Color(0xFF2A9D8F) : Colors.white,
                            ),
                            minHeight: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: isLocked ? const Color(0xFFD4F3ED) : const Color(0xFFFDE8E1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isLocked ? '100%' : '${summary.progressPercent.toInt()}%',
                          style: TextStyle(
                            color: isLocked ? const Color(0xFF1F7368) : const Color(0xFFC84729),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Bottom Stats Row & Swipe/Lock Hint
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isLocked
                            ? 'تاريخ الدفع: ${period?.disbursedAt ?? "مكتمل"}'
                            : 'نسبة الإنجاز: ${summary.progressPercent.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        isLocked
                            ? 'الشهر مقفل ومسدد'
                            : (isReached
                                ? 'الفائض المحسوب: ${CurrencyFormatter.formatIqd(summary.surplus)}'
                                : 'النقص المتبقي: ${CurrencyFormatter.formatIqd(summary.shortfall)}'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. Cash vs Electronic Breakdown ---
  Widget _buildPaymentMethodsRow(BuildContext context, dynamic summary) {
    return Row(
      children: [
        // Electronic Payments Card (Left in RTL, index 0 in Row)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD8EBF2)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF293241).withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'المقبوضات الإلكترونية',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF293241),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2F1F7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.phone_android_outlined,
                        color: Color(0xFF3D5A80),
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: onNavigateToPayments,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE2F1F7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          color: Color(0xFF3D5A80),
                          size: 18,
                        ),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatIqd(summary.electronicTotal),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF293241),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Cash Payments Card (Right in RTL, index 1 in Row)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD8EBF2)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF293241).withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'المقبوضات النقدية',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF293241),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2F1F7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Color(0xFF3D5A80),
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: onNavigateToPayments,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE2F1F7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          color: Color(0xFF3D5A80),
                          size: 18,
                        ),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatIqd(summary.cashTotal),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF293241),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 4. Contributor Status Counters ---
  Widget _buildStatusCounters(BuildContext context, dynamic summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD8EBF2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF293241).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Details Button on Left
              InkWell(
                onTap: onNavigateToStatuses,
                child: const Row(
                  children: [
                    Icon(Icons.chevron_left, color: Color(0xFF3D5A80), size: 18),
                    SizedBox(width: 2),
                    Text(
                      'عرض التفاصيل',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D5A80),
                      ),
                    ),
                  ],
                ),
              ),

              // Title on Right
              const Row(
                children: [
                  Text(
                    'حالات تسديد المساهمين',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF293241),
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.groups_rounded,
                    color: Color(0xFF3D5A80),
                    size: 22,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 3 Columns Row: Fully Paid (Right), Partial (Center), Unpaid (Left)
          Row(
            children: [
              // 3. Unpaid (غير مسدد) - Left in RTL
              Expanded(
                child: InkWell(
                  onTap: onNavigateToStatuses,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF0EC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF8C8B8)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.groups_rounded,
                          color: Color(0xFFEE6C4D),
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${summary.unpaidCount}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEE6C4D),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'غير مسدد',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF293241),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 2. Partial (مسدد جزئياً) - Center
              Expanded(
                child: InkWell(
                  onTap: onNavigateToStatuses,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF4FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFB5D7E8)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.groups_rounded,
                          color: Color(0xFF3D5A80),
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${summary.partialPaidCount}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D5A80),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'مسدد جزئياً',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF293241),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 1. Fully Paid (مسدد بالكامل) - Right in RTL
              Expanded(
                child: InkWell(
                  onTap: onNavigateToStatuses,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F7F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFA3E2D4)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.groups_rounded,
                          color: Color(0xFF2A9D8F),
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${summary.fullyPaidCount}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2A9D8F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'مسدد بالكامل',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF293241),
                          ),
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
    );
  }

  // --- 5. Surplus & Gift Balance Card ---
  Widget _buildSurplusCard(BuildContext context, dynamic summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD8EBF2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF293241).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: سجل الهدايا pill + Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: onNavigateToGifts,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2F1F7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chevron_left, size: 14, color: Color(0xFF3D5A80)),
                      SizedBox(width: 2),
                      Text(
                        'سجل الهدايا',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D5A80),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                CurrencyFormatter.formatIqd(summary.unspentSurplus),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF293241),
                ),
              ),
            ],
          ),

          // Right: Gift Icon in circle + Title & Subtitle
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'صندوق الفائض والهدايا',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF293241),
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'مساهمات إضافية خارج الكفالة',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF7A8B99),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Color(0xFFEE6C4D),
                  size: 26,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 6. Recent Payments in this month ---
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
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF293241),
              ),
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD8EBF2)),
            ),
            child: const Center(
              child: Text(
                'لا توجد دفعات مسجلة لهذا الشهر حتى الآن',
                style: TextStyle(color: Color(0xFF7A8B99), fontSize: 13),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFD8EBF2)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: p.isCash
              ? AppTheme.cashColor.withValues(alpha: 0.12)
              : AppTheme.electronicColor.withValues(alpha: 0.12),
          child: Icon(
            p.isCash ? Icons.account_balance_wallet_outlined : Icons.phone_android_outlined,
            color: p.isCash ? AppTheme.cashColor : AppTheme.electronicColor,
            size: 20,
          ),
        ),
        title: Text(
          p.contributorName ?? 'مساهم',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF293241),
            decoration: p.isVoid ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${p.methodArabicName} • ${p.paidAt.split('T').first}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF7A8B99)),
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
                color: p.isVoid ? Colors.grey : AppTheme.yinMnBlue,
                decoration: p.isVoid ? TextDecoration.lineThrough : null,
              ),
            ),
            if (p.isVoid)
              const Text(
                'ملغاة',
                style: TextStyle(
                  color: AppTheme.burntSienna,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Handling New Payment & Checking Month Lock ---
  void _handleOpenNewPayment(BuildContext context) {
    final period = state.selectedPeriod;
    if (period != null && period.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.burntSienna,
          content: Text(
            'هذا الشهر مقفل وتم دفع كفالته مسبقاً، ولا يمكن تسجيل دفعات جديدة إليه.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }
    _openNewPaymentDialog(context);
  }

  void _openNewPaymentDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => NewPaymentDialog(state: state),
    );
  }

  // --- Dialog: دفع الكفالة وقفل الشهر (Disburse Sponsorship & Lock Period) ---
  void _showDisburseSponsorshipDialog(BuildContext context) {
    final period = state.selectedPeriod;
    final summary = state.currentSummary;
    if (period == null || summary == null) return;

    if (period.isLocked) {
      // Month is already locked: Show management/details dialog with unlock option
      showDialog(
        context: context,
        builder: (ctx) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.lock_rounded, color: AppTheme.yinMnBlue, size: 24),
                  const SizedBox(width: 8),
                  Text('كفالة شهر ${period.arabicMonthName}'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F7F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA3E2D4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF2A9D8F), size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'تم دفع كفالة هذا الشهر وقفله رسمياً.',
                            style: const TextStyle(
                              color: Color(0xFF1E3A5F),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '• مبلغ الكفالة المدفوع: ${CurrencyFormatter.formatIqd(period.disbursedAmountIqd ?? summary.collectedTotal)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• تاريخ الدفع: ${period.disbursedAt ?? "غير محدد"}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF5B6E7A)),
                  ),
                  if (period.disbursementNotes != null && period.disbursementNotes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '• الملاحظات: ${period.disbursementNotes}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF5B6E7A)),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Text(
                    'لا يمكن تسجيل دفعات جديدة ما دام الشهر مقفلاً.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('إغلاق'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => Directionality(
                        textDirection: TextDirection.rtl,
                        child: AlertDialog(
                          title: const Text('إلغاء قفل الشهر؟'),
                          content: const Text(
                            'هل أنت متأكد من رغبتك بإلغاء قفل هذا الشهر والسماح بإضافة وتعديل التسديدات مجدداً؟',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(c).pop(false),
                              child: const Text('تراجع'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(c).pop(true),
                              child: const Text('نعم، إلغاء القفل'),
                            ),
                          ],
                        ),
                      ),
                    );
                    if (confirm == true) {
                      await state.unlockCurrentPeriod();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppTheme.yinMnBlue,
                            content: Text('تم إلغاء قفل الشهر بنجاح.'),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.lock_open_rounded, size: 16),
                  label: const Text('إلغاء قفل الشهر'),
                ),
              ],
            ),
          );
        },
      );
      return;
    }

    // Month is NOT locked yet: Show "دفع الكفالة" Dialog
    final defaultAmount = summary.collectedTotal > 0 ? summary.collectedTotal : summary.targetIqd;
    final amountController = TextEditingController(text: CurrencyFormatter.formatForInput(defaultAmount));
    final notesController = TextEditingController();
    DateTime paymentDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final formattedDate = DateFormat('yyyy-MM-dd').format(paymentDate);

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.yinMnBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.volunteer_activism_rounded, color: AppTheme.yinMnBlue, size: 22),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'دفع الكفالة — ${period.arabicMonthName}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF0EC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF8C8B8)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, color: AppTheme.burntSienna, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'تنبيه: عند تأكيد دفع الكفالة، سيتم قفل الشهر واعتباره مسدداً بالكامل، ولن يُسمح بإضافة تسديدات جديدة لهذا الشهر بعد ذلك.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8A301E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Amount Input
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'مبلغ الكفالة المدفوع (د.ع) *',
                          suffixText: 'د.ع',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Payment Date Picker Field
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: paymentDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setDialogState(() => paymentDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.cardBorderLight),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, size: 20, color: AppTheme.yinMnBlue),
                                  const SizedBox(width: 8),
                                  const Text('تاريخ الدفع: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Optional Notes
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات الصرف (اختياري)',
                          hintText: 'مثال: تم تسليم الكفالة لإدارة الرعاية',
                          prefixIcon: Icon(Icons.notes_outlined),
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
                  ElevatedButton.icon(
                    onPressed: () async {
                      final amount = CurrencyFormatter.parseIqd(amountController.text);
                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('يرجى إدخال مبلغ صحيح أكبر من صفر')),
                        );
                        return;
                      }
                      Navigator.of(ctx).pop();
                      try {
                        await state.disburseSponsorship(
                          amountIqd: amount,
                          disbursedAt: formattedDate,
                          notes: notesController.text.trim().isNotEmpty
                              ? notesController.text.trim()
                              : null,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.yinMnBlue,
                              content: Text(
                                'تم دفع كفالة شهر ${period.arabicMonthName} بمبلغ ${CurrencyFormatter.formatIqd(amount)} وقفل الشهر بنجاح 🔒',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red,
                              content: Text('خطأ: $e'),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('تسديد الكفالة'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditTargetDialog(BuildContext context) {
    final period = state.selectedPeriod;
    if (period == null) return;
    final controller = TextEditingController(text: CurrencyFormatter.formatForInput(period.targetAmountIqd));
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

// Target Concentric Bullseye Watermark Painter
class _TargetBullseyePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    final center = Offset(size.width * 0.7, size.height * 0.45);
    canvas.drawCircle(center, 12, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;
    canvas.drawCircle(center, 28, paint);
    canvas.drawCircle(center, 46, paint);
    canvas.drawCircle(center, 66, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
