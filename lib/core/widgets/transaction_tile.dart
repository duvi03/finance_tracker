import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:finance_tracker/core/constants/app_colors.dart';
import 'package:finance_tracker/core/utils/currency_formatter.dart';
import 'package:finance_tracker/core/utils/date_formatter.dart';
import 'package:finance_tracker/data/models/transaction_model.dart';
import 'package:finance_tracker/data/repositories/finance_repository.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  Color _getTypeColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return AppColors.income;
      case TransactionType.expense:
        return AppColors.expense;
      case TransactionType.saving:
        return AppColors.savings;
      case TransactionType.gold:
        return AppColors.gold;
      case TransactionType.emi:
        return AppColors.emi;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = Get.find<FinanceRepository>();
    final category = repo.getCategoryById(transaction.categoryId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = _getTypeColor(transaction.type);

    return Dismissible(
      key: Key(transaction.id),
      direction: onDelete != null ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Transaction'),
                content: Text('Are you sure you want to delete "${transaction.title}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete?.call(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Category Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(category.icon, color: typeColor, size: 22),
                ),
                const SizedBox(width: 14),

                // Title & Category & Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              transaction.type.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: typeColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormatter.formatRelative(transaction.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                      if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          transaction.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Amount
                Text(
                  '${transaction.type.isIncome ? '+' : '-'}${CurrencyFormatter.format(transaction.amount, symbol: repo.settings.value.currencySymbol)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: transaction.type.isIncome ? AppColors.income : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
