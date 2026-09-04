import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:finance_tracker/core/constants/app_colors.dart';
import 'package:finance_tracker/core/widgets/quick_add_dialog.dart';
import 'package:finance_tracker/features/budgets/views/budgets_view.dart';
import 'package:finance_tracker/features/dashboard/views/dashboard_view.dart';
import 'package:finance_tracker/features/emi/views/emi_view.dart';
import 'package:finance_tracker/features/gold/views/gold_view.dart';
import 'package:finance_tracker/features/recurring/views/recurring_view.dart';
import 'package:finance_tracker/features/reports/views/reports_view.dart';
import 'package:finance_tracker/features/savings/views/savings_view.dart';
import 'package:finance_tracker/features/settings/views/settings_view.dart';
import 'package:finance_tracker/features/transactions/views/transactions_view.dart';

class MainShellController extends GetxController {
  // Mobile Tab Index (0..4)
  final currentMobileTab = 0.obs;

  // Desktop / Rail Index (0..8)
  final currentDesktopIndex = 0.obs;

  void changeTab(int index) {
    currentMobileTab.value = index.clamp(0, 4);
    // Sync desktop index
    if (index == 0) currentDesktopIndex.value = 0; // Dashboard
    if (index == 1) currentDesktopIndex.value = 1; // Transactions
    if (index == 2) currentDesktopIndex.value = 2; // EMIs
    if (index == 3) currentDesktopIndex.value = 3; // Savings
    if (index == 4) currentDesktopIndex.value = 7; // Reports
  }

  void changeDesktopIndex(int index) {
    currentDesktopIndex.value = index;
    if (index == 0) {
      currentMobileTab.value = 0;
    } else if (index == 1) {
      currentMobileTab.value = 1;
    } else if (index == 2) {
      currentMobileTab.value = 2;
    } else if (index == 3 || index == 4) {
      currentMobileTab.value = 3;
    } else {
      currentMobileTab.value = 4;
    }
  }
}

class MainShellView extends StatelessWidget {
  const MainShellView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MainShellController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktopOrWeb = constraints.maxWidth >= 800;

        if (isDesktopOrWeb) {
          return Scaffold(
            body: Row(
              children: [
                // Desktop Sidebar Navigation
                Container(
                  width: 240,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    border: Border(
                      right: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header / Brand
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Artha',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'Offline Finance',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Quick Add Button in Sidebar
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(double.infinity, 44),
                          ),
                          onPressed: () => QuickAddModal.show(context),
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Add Entry', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),

                      // Navigation Items
                      Expanded(
                        child: Obx(() {
                          final selectedIdx = controller.currentDesktopIndex.value;
                          return ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            children: [
                              _SidebarItem(
                                icon: Icons.dashboard_outlined,
                                selectedIcon: Icons.dashboard,
                                label: 'Dashboard',
                                isSelected: selectedIdx == 0,
                                onTap: () => controller.changeDesktopIndex(0),
                              ),
                              _SidebarItem(
                                icon: Icons.receipt_long_outlined,
                                selectedIcon: Icons.receipt_long,
                                label: 'Transactions',
                                isSelected: selectedIdx == 1,
                                onTap: () => controller.changeDesktopIndex(1),
                              ),
                              _SidebarItem(
                                icon: Icons.credit_card_outlined,
                                selectedIcon: Icons.credit_card,
                                label: 'EMIs & Loans',
                                isSelected: selectedIdx == 2,
                                onTap: () => controller.changeDesktopIndex(2),
                              ),
                              _SidebarItem(
                                icon: Icons.savings_outlined,
                                selectedIcon: Icons.savings,
                                label: 'Savings Goals',
                                isSelected: selectedIdx == 3,
                                onTap: () => controller.changeDesktopIndex(3),
                              ),
                              _SidebarItem(
                                icon: Icons.monetization_on_outlined,
                                selectedIcon: Icons.monetization_on,
                                label: 'Gold Investment',
                                isSelected: selectedIdx == 4,
                                onTap: () => controller.changeDesktopIndex(4),
                              ),
                              _SidebarItem(
                                icon: Icons.pie_chart_outline,
                                selectedIcon: Icons.pie_chart,
                                label: 'Budgets',
                                isSelected: selectedIdx == 5,
                                onTap: () => controller.changeDesktopIndex(5),
                              ),
                              _SidebarItem(
                                icon: Icons.repeat,
                                selectedIcon: Icons.repeat_on,
                                label: 'Recurring Rules',
                                isSelected: selectedIdx == 6,
                                onTap: () => controller.changeDesktopIndex(6),
                              ),
                              _SidebarItem(
                                icon: Icons.bar_chart_outlined,
                                selectedIcon: Icons.bar_chart,
                                label: 'Reports & Analytics',
                                isSelected: selectedIdx == 7,
                                onTap: () => controller.changeDesktopIndex(7),
                              ),
                              _SidebarItem(
                                icon: Icons.settings_outlined,
                                selectedIcon: Icons.settings,
                                label: 'Settings & Backup',
                                isSelected: selectedIdx == 8,
                                onTap: () => controller.changeDesktopIndex(8),
                              ),
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                // Main Body for Selected Screen
                Expanded(
                  child: Obx(() {
                    switch (controller.currentDesktopIndex.value) {
                      case 0:
                        return const DashboardView();
                      case 1:
                        return const TransactionsView();
                      case 2:
                        return const EMIView();
                      case 3:
                        return const SavingsView();
                      case 4:
                        return const GoldView();
                      case 5:
                        return const BudgetsView();
                      case 6:
                        return const RecurringView();
                      case 7:
                        return const ReportsView();
                      case 8:
                        return const SettingsView();
                      default:
                        return const DashboardView();
                    }
                  }),
                ),
              ],
            ),
          );
        }

        // --- Mobile Bottom Navigation View (< 800px) ---
        return Obx(() {
          final tab = controller.currentMobileTab.value;
          return Scaffold(
            body: IndexedStack(
              index: tab,
              children: const [
                DashboardView(),
                TransactionsView(),
                EMIView(),
                _InvestmentsCombinedTab(),
                _MoreCombinedTab(),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: tab,
              onTap: controller.changeTab,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined),
                  activeIcon: Icon(Icons.receipt_long),
                  label: 'Transactions',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.credit_card_outlined),
                  activeIcon: Icon(Icons.credit_card),
                  label: 'EMIs',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.savings_outlined),
                  activeIcon: Icon(Icons.savings),
                  label: 'Investments',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu),
                  activeIcon: Icon(Icons.menu_open),
                  label: 'More',
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(
          isSelected ? selectedIcon : icon,
          color: isSelected ? AppColors.primary : null,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primary : null,
            fontSize: 13,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Combined Investments Tab for Mobile (Savings Goals & Gold Investment)
class _InvestmentsCombinedTab extends StatefulWidget {
  const _InvestmentsCombinedTab();

  @override
  State<_InvestmentsCombinedTab> createState() => _InvestmentsCombinedTabState();
}

class _InvestmentsCombinedTabState extends State<_InvestmentsCombinedTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investments & Savings', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.savings, size: 20), text: 'Savings Goals'),
            Tab(icon: Icon(Icons.monetization_on, size: 20), text: 'Gold Tracker'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SavingsView(hideAppBar: true),
          GoldView(hideAppBar: true),
        ],
      ),
    );
  }
}

/// "More" Tab for Mobile (Budgets, Recurring Rules, Reports, Settings)
class _MoreCombinedTab extends StatelessWidget {
  const _MoreCombinedTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('More Features', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MoreMenuCard(
            title: 'Monthly Budgets',
            subtitle: 'Set category spending limits & alerts',
            icon: Icons.pie_chart,
            color: AppColors.expense,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Scaffold(body: BudgetsView())),
            ),
          ),
          _MoreMenuCard(
            title: 'Recurring Rules',
            subtitle: 'Automated salary and subscription rules',
            icon: Icons.repeat,
            color: AppColors.income,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Scaffold(body: RecurringView())),
            ),
          ),
          _MoreMenuCard(
            title: 'Reports & Analytics',
            subtitle: 'Visual charts, donut breakdowns & net worth',
            icon: Icons.bar_chart,
            color: AppColors.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Scaffold(body: ReportsView())),
            ),
          ),
          _MoreMenuCard(
            title: 'Settings & Data Backup',
            subtitle: 'Theme, currency, JSON/CSV export & restore',
            icon: Icons.settings,
            color: Colors.blueGrey,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Scaffold(body: SettingsView())),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreMenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MoreMenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
