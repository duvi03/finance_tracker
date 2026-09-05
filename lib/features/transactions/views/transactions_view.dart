import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:finance_tracker/core/constants/app_colors.dart';
import 'package:finance_tracker/core/utils/currency_formatter.dart';
import 'package:finance_tracker/core/utils/responsive_utils.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            onPressed: () => QuickAddModal.show(context),
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
        // Filter logic
        final query = _searchController.text.trim().toLowerCase();
        var list = repo.transactions.where((t) {
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

        final totalFiltered = list.fold(0.0, (sum, t) => sum + (t.type.isIncome ? t.amount : -t.amount));

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              children: [
                // Search bar & Filters
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: [
                      // Search TextField
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search by title, category, notes...',
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
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Filter chips scroll
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text('All'),
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

                // Quick stats summary of filtered list
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.isMobileSmall ? 10 : 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Showing ${list.length} transactions',
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
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Net: ${CurrencyFormatter.format(totalFiltered)}',
                          style: TextStyle(
                            fontSize: context.isMobileSmall ? 12 : 13,
                            fontWeight: FontWeight.bold,
                            color: totalFiltered >= 0 ? AppColors.income : AppColors.expense,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 12),

                // Transactions List
                Expanded(
                  child: list.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 54, color: AppColors.lightTextMuted),
                              const SizedBox(height: 12),
                              const Text(
                                'No matching transactions',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Try clearing filters or search term.',
                                style: TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: context.isMobileSmall ? 10 : 16, vertical: 8),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final tx = list[index];
                            return TransactionTile(
                              transaction: tx,
                              onDelete: () => repo.deleteTransaction(tx.id),
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
        onPressed: () => QuickAddModal.show(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
