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
              indicatorColor: AppTheme.primaryGreen.withOpacity(0.18),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryGreen),
                  label: 'الرئيسية',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long, color: AppTheme.primaryGreen),
                  label: 'المدفوعات',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people, color: AppTheme.primaryGreen),
                  label: 'المساهمون',
                ),
                NavigationDestination(
                  icon: Icon(Icons.fact_check_outlined),
                  selectedIcon: Icon(Icons.fact_check, color: AppTheme.primaryGreen),
                  label: 'كشف السداد',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings, color: AppTheme.primaryGreen),
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
