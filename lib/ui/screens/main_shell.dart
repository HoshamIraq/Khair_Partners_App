import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/app_state.dart';
import 'contributors_screen.dart';
import 'dashboard_screen.dart';
import 'gifts_screen.dart';
import 'payment_statuses_screen.dart';
import 'payments_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  final AppState state;

  const MainShell({super.key, required this.state});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final screens = [
          DashboardScreen(
            state: widget.state,
            onNavigateToPayments: () => setState(() => _currentIndex = 1),
            onNavigateToStatuses: () => setState(() => _currentIndex = 3),
            onNavigateToGifts: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => GiftsScreen(state: widget.state)),
              );
            },
          ),
          PaymentsScreen(state: widget.state),
          ContributorsScreen(state: widget.state),
          PaymentStatusesScreen(state: widget.state),
          SettingsScreen(state: widget.state),
        ];

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
              backgroundColor: Colors.white,
              indicatorColor: const Color(0xFFD4EFF8),
              elevation: 2,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.grid_view_rounded, color: Color(0xFF6B7E8C)),
                  selectedIcon: Icon(Icons.grid_view_rounded, color: AppTheme.yinMnBlue),
                  label: 'الرئيسية',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined, color: Color(0xFF6B7E8C)),
                  selectedIcon: Icon(Icons.receipt_long, color: AppTheme.yinMnBlue),
                  label: 'المدفوعات',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline, color: Color(0xFF6B7E8C)),
                  selectedIcon: Icon(Icons.people, color: AppTheme.yinMnBlue),
                  label: 'المساهمون',
                ),
                NavigationDestination(
                  icon: Icon(Icons.check_box_outlined, color: Color(0xFF6B7E8C)),
                  selectedIcon: Icon(Icons.check_box, color: AppTheme.yinMnBlue),
                  label: 'كشف السداد',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined, color: Color(0xFF6B7E8C)),
                  selectedIcon: Icon(Icons.settings, color: AppTheme.yinMnBlue),
                  label: 'الإعدادات',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
