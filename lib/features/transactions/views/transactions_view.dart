import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:finance_tracker/core/constants/app_colors.dart';
import 'package:finance_tracker/core/utils/currency_formatter.dart';
import 'package:finance_tracker/core/utils/date_formatter.dart';
import 'package:finance_tracker/core/utils/responsive_utils.dart';
import 'package:finance_tracker/core/widgets/edit_transaction_dialog.dart';
import 'package:finance_tracker/core/widgets/quick_add_dialog.dart';
import 'package:finance_tracker/core/widgets/transaction_tile.dart';
import 'package:finance_tracker/data/models/transaction_model.dart';
import 'package:finance_tracker/data/repositories/finance_repository.dart';

class TransactionsView extends StatefulWidget {
  const TransactionsView({super.key});

  @override
  State<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<TransactionsView> {
  final FinanceRepository repo = Get.find<FinanceRepository>();

  final _searchController = TextEditingController();
  TransactionType? _filterType;
  String? _filterCategoryId;
  String _sortBy = 'date_desc'; // 'date_desc', 'date_asc', 'amount_desc', 'amount_asc'

  // Month-wise filter state
  bool _filterByMonth = true;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedMonth = 12;
        _selectedYear--;
      } else {
        _selectedMonth--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_selectedMonth == 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else {
        _selectedMonth++;
      }
    });
  }

  void _resetToCurrentMonth() {
    setState(() {
      _selectedMonth = DateTime.now().month;
      _selectedYear = DateTime.now().year;
    });
  }

  DateTime get _effectiveDateForNewEntry {
    if (!_filterByMonth) return DateTime.now();
    final now = DateTime.now();
    if (_selectedYear == now.year && _selectedMonth == now.month) {
      return now;
    }
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    final day = now.day.clamp(1, daysInMonth);
    return DateTime(_selectedYear, _selectedMonth, day);
  }

  Future<void> _selectMonthYear(BuildContext context) async {
    final now = DateTime.now();
    int tempYear = _selectedYear;
    int tempMonth = _selectedMonth;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Month & Year'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setDialogState(() => tempYear--),
                  ),
                  Text(
                    '$tempYear',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setDialogState(() => tempYear++),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(12, (i) {
                  final monthNum = i + 1;
                  final isSelected = tempMonth == monthNum;
                  final monthName = DateFormatter.formatMonthYear(DateTime(2026, monthNum, 1)).split(' ').first;
                  return ChoiceChip(
                    label: Text(monthName),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      if (val) setDialogState(() => tempMonth = monthNum);
                    },
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  tempYear = now.year;
                  tempMonth = now.month;
                });
              },
              child: const Text('Current Month'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                setState(() {
                  _filterByMonth = true;
                  _selectedYear = tempYear;
                  _selectedMonth = tempMonth;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Add Transaction',
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => QuickAddModal.show(context, initialDate: _effectiveDateForNewEntry),
          ),
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {
              final csv = repo.exportTransactionsCsv();
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Exported CSV Preview'),
                  content: Container(
                    constraints: BoxConstraints(
                      maxWidth: 500,
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        csv,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        final query = _searchController.text.trim().toLowerCase();

        // Filter transactions
        var list = repo.transactions.where((t) {
          if (_filterByMonth) {
            if (t.date.month != _selectedMonth || t.date.year != _selectedYear) {
              return false;
            }
          }
          if (_filterType != null && t.type != _filterType) return false;
          if (_filterCategoryId != null && t.categoryId != _filterCategoryId) return false;
          if (query.isNotEmpty) {
            final cat = repo.getCategoryById(t.categoryId).name.toLowerCase();
            final title = t.title.toLowerCase();
            final notes = (t.notes ?? '').toLowerCase();
            if (!title.contains(query) && !cat.contains(query) && !notes.contains(query)) {
              return false;
            }
          }
          return true;
        }).toList();

        // Sort logic
        if (_sortBy == 'date_desc') {
          list.sort((a, b) => b.date.compareTo(a.date));
        } else if (_sortBy == 'date_asc') {
          list.sort((a, b) => a.date.compareTo(b.date));
        } else if (_sortBy == 'amount_desc') {
          list.sort((a, b) => b.amount.compareTo(a.amount));
        } else if (_sortBy == 'amount_asc') {
          list.sort((a, b) => a.amount.compareTo(b.amount));
        }

        // Financial figures for the active scope (month or all-time)
        final num scopeOpeningBalance = _filterByMonth
            ? repo.getOpeningBalance(_selectedMonth, _selectedYear)
            : 0;
        final num scopeIncome = _filterByMonth
            ? repo.getTotalIncome(month: _selectedMonth, year: _selectedYear)
            : repo.getTotalIncome();
        final num scopeExpense = _filterByMonth
            ? repo.getTotalExpenses(month: _selectedMonth, year: _selectedYear)
            : repo.getTotalExpenses();
        final num scopeEmi = _filterByMonth
            ? repo.getTotalEmiPaid(month: _selectedMonth, year: _selectedYear)
            : repo.getTotalEmiPaid();
        final num scopeSavings = _filterByMonth
            ? repo.getTotalSavingsAllocated(month: _selectedMonth, year: _selectedYear)
            : repo.getTotalSavingsAllocated();
        final num scopeGold = _filterByMonth
            ? repo.getTotalGoldInvested(month: _selectedMonth, year: _selectedYear)
            : repo.getTotalGoldInvested();
        final num scopeTotalOutflow = scopeExpense + scopeEmi + scopeSavings + scopeGold;
        final num scopeAvailableMoney = scopeOpeningBalance + scopeIncome;
        final num scopeClosingBalance = _filterByMonth
            ? repo.getMonthClosingBalance(_selectedMonth, _selectedYear)
            : repo.allTimeAvailableBalance;

        final currentSelectedDate = DateTime(_selectedYear, _selectedMonth, 1);
        final monthTitle = _filterByMonth
            ? DateFormatter.formatMonthYear(currentSelectedDate)
            : 'All Time';

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                // Month Navigation Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            tooltip: 'Previous Month',
                            onPressed: _filterByMonth ? _previousMonth : null,
                          ),
                          InkWell(
                            onTap: () => _selectMonthYear(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_month,
                                    size: 18,
                                    color: _filterByMonth ? AppColors.primary : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    monthTitle,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: context.isMobileSmall ? 14 : 16,
                                      color: _filterByMonth ? null : Colors.grey,
                                    ),
                                  ),
                                  if (_filterByMonth) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_drop_down, size: 20),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                tooltip: 'Next Month',
                                onPressed: _filterByMonth ? _nextMonth : null,
                              ),
                              FilterChip(
                                visualDensity: VisualDensity.compact,
                                label: Text(
                                  _filterByMonth ? 'Month' : 'All Time',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                selected: _filterByMonth,
                                onSelected: (val) {
                                  setState(() {
                                    _filterByMonth = val;
                                    if (val) _resetToCurrentMonth();
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Scope Summary Card (Monthly Carry-Forward or All-Time)
                _buildScopeSummaryCard(
                  context,
                  isDark: isDark,
                  filterByMonth: _filterByMonth,
                  monthTitle: monthTitle,
                  openingBalance: scopeOpeningBalance,
                  income: scopeIncome,
                  totalOutflow: scopeTotalOutflow,
                  availableMoney: scopeAvailableMoney,
                  closingBalance: scopeClosingBalance,
                ),

                // Search Bar & Filter Chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: Column(
                    children: [
                      // Search TextField
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search title, category, notes in $monthTitle...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Filter chips scroll
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text('All Types'),
                              selected: _filterType == null,
                              onSelected: (_) => setState(() => _filterType = null),
                            ),
                            const SizedBox(width: 6),
                            ...TransactionType.values.map((type) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: FilterChip(
                                  label: Text(type.displayName),
                                  selected: _filterType == type,
                                  onSelected: (selected) {
                                    setState(() => _filterType = selected ? type : null);
                                  },
                                ),
                              );
                            }),
                            const SizedBox(width: 8),

                            // Sort dropdown
                            DropdownButton<String>(
                              value: _sortBy,
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(value: 'date_desc', child: Text('Newest first')),
                                DropdownMenuItem(value: 'date_asc', child: Text('Oldest first')),
                                DropdownMenuItem(value: 'amount_desc', child: Text('Highest amount')),
                                DropdownMenuItem(value: 'amount_asc', child: Text('Lowest amount')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _sortBy = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Quick stats summary
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.isMobileSmall ? 12 : 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Showing ${list.length} transaction${list.length == 1 ? '' : 's'} for $monthTitle',
                          style: TextStyle(
                            fontSize: context.isMobileSmall ? 11 : 12,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _filterByMonth
                            ? 'Remaining: ${CurrencyFormatter.format(scopeClosingBalance)}'
                            : 'Net: ${CurrencyFormatter.format(scopeClosingBalance)}',
                        style: TextStyle(
                          fontSize: context.isMobileSmall ? 11 : 12,
                          fontWeight: FontWeight.bold,
                          color: scopeClosingBalance >= 0 ? AppColors.income : AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 8),

                // Transactions List
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final showOpeningTile = _filterByMonth &&
                          query.isEmpty &&
                          _filterType == null &&
                          _filterCategoryId == null;

                      if (list.isEmpty) {
                        return ListView(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.isMobileSmall ? 10 : 16,
                            vertical: 6,
                          ),
                          children: [
                            if (showOpeningTile)
                              _buildOpeningBalanceTile(
                                context,
                                date: currentSelectedDate,
                                openingBalance: scopeOpeningBalance,
                                isDark: isDark,
                              ),
                            const SizedBox(height: 36),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 52, color: AppColors.lightTextMuted),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No transactions found for $monthTitle',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Tap the + button to add an income or expense.',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      final totalCount = list.length + (showOpeningTile ? 1 : 0);

                      return ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.isMobileSmall ? 10 : 16,
                          vertical: 6,
                        ),
                        itemCount: totalCount,
                        itemBuilder: (context, index) {
                          if (showOpeningTile && index == 0) {
                            return _buildOpeningBalanceTile(
                              context,
                              date: currentSelectedDate,
                              openingBalance: scopeOpeningBalance,
                              isDark: isDark,
                            );
                          }
                          final tx = list[showOpeningTile ? index - 1 : index];
                          return TransactionTile(
                            transaction: tx,
                            onEdit: () => EditTransactionModal.show(context, tx),
                            onDelete: () => repo.deleteTransaction(tx.id),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_transactions',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Quick Add',
        onPressed: () => QuickAddModal.show(context, initialDate: _effectiveDateForNewEntry),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildScopeSummaryCard(
    BuildContext context, {
    required bool isDark,
    required bool filterByMonth,
    required String monthTitle,
    required num openingBalance,
    required num income,
    required num totalOutflow,
    required num availableMoney,
    required num closingBalance,
  }) {
    if (!filterByMonth) {
      // All-Time Summary Card
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        padding: EdgeInsets.all(context.isMobileSmall ? 12 : 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (closingBalance >= 0 ? AppColors.income : AppColors.expense)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        size: 16,
                        color: closingBalance >= 0 ? AppColors.income : AppColors.expense,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'All Time Net Balance',
                      style: TextStyle(
                        fontSize: context.isMobileSmall ? 12 : 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    CurrencyFormatter.format(closingBalance),
                    style: TextStyle(
                      fontSize: context.isMobileSmall ? 16 : 18,
                      fontWeight: FontWeight.w800,
                      color: closingBalance >= 0 ? AppColors.income : AppColors.expense,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildSimpleStat(
                    label: 'Total Income',
                    amount: income,
                    color: AppColors.income,
                    icon: Icons.arrow_downward,
                    prefix: '+',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSimpleStat(
                    label: 'Total Outflows',
                    amount: totalOutflow,
                    color: AppColors.expense,
                    icon: Icons.arrow_upward,
                    prefix: '-',
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Monthly Carry-Forward Summary Card
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: EdgeInsets.all(context.isMobileSmall ? 12 : 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.assessment_outlined, color: AppColors.primary, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$monthTitle Summary',
                    style: TextStyle(
                      fontSize: context.isMobileSmall ? 13 : 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sync_alt, size: 11, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      'Carry-Forward',
                      style: TextStyle(
                        fontSize: context.isMobileSmall ? 9.5 : 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSummaryItem(
                    width: width,
                    label: 'Opening Balance',
                    amount: openingBalance,
                    color: Colors.blue.shade600,
                    icon: Icons.account_balance_outlined,
                    note: 'From previous month',
                  ),
                  _buildSummaryItem(
                    width: width,
                    label: 'Income',
                    amount: income,
                    color: AppColors.income,
                    icon: Icons.arrow_downward,
                    prefix: '+',
                    note: 'Total inflow',
                  ),
                  _buildSummaryItem(
                    width: width,
                    label: 'Expenses & Outflows',
                    amount: totalOutflow,
                    color: AppColors.expense,
                    icon: Icons.arrow_upward,
                    prefix: '-',
                    note: 'Spend & allocations',
                  ),
                  _buildSummaryItem(
                    width: width,
                    label: 'Remaining Balance',
                    amount: closingBalance,
                    color: closingBalance >= 0 ? AppColors.income : AppColors.expense,
                    icon: Icons.account_balance_wallet,
                    note: 'Carries to next month',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Money (Opening + Income)',
                  style: TextStyle(
                    fontSize: context.isMobileSmall ? 10.5 : 11.5,
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(availableMoney),
                  style: TextStyle(
                    fontSize: context.isMobileSmall ? 11.5 : 12.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat({
    required String label,
    required num amount,
    required Color color,
    required IconData icon,
    String prefix = '',
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$prefix${CurrencyFormatter.format(amount)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required double width,
    required String label,
    required num amount,
    required Color color,
    required IconData icon,
    String prefix = '',
    String? note,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '$prefix${CurrencyFormatter.format(amount)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            if (note != null) ...[
              const SizedBox(height: 2),
              Text(
                note,
                style: const TextStyle(fontSize: 9.5, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOpeningBalanceTile(
    BuildContext context, {
    required DateTime date,
    required num openingBalance,
    required bool isDark,
  }) {
    final isNegative = openingBalance < 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.blue.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_toggle_off, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '1 ${DateFormatter.formatMonthYear(date)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'OPENING BALANCE',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'Carried Forward Balance',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                const Text(
                  'Brought forward from previous month',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              CurrencyFormatter.format(openingBalance),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: isNegative ? AppColors.expense : (openingBalance > 0 ? Colors.blue.shade700 : Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
