import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:finance_tracker/core/constants/app_colors.dart';
import 'package:finance_tracker/core/utils/currency_formatter.dart';
import 'package:finance_tracker/core/utils/date_formatter.dart';
import 'package:finance_tracker/core/utils/responsive_utils.dart';
import 'package:finance_tracker/data/models/emi_model.dart';
import 'package:finance_tracker/data/repositories/finance_repository.dart';

class EMIView extends StatelessWidget {
  const EMIView({super.key});

  void _showNewEmiDialog(BuildContext context) {
    final repo = Get.find<FinanceRepository>();
    final uuid = const Uuid();

    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final installmentsController = TextEditingController(text: '12');
    DateTime selectedStartDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New EMI Plan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item / Purchase Name',
                    hintText: 'e.g. Smartphone, Laptop',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    prefixText: '${repo.settings.value.currencySymbol} ',
                    labelText: 'Total Purchase Cost',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: installmentsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Number of Installments (Months)',
                    helperText: 'e.g. 3, 6, 12, 24 months',
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedStartDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) setState(() => selectedStartDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'First Installment Date',
                      prefixIcon: Icon(Icons.calendar_today, size: 20),
                    ),
                    child: Text(DateFormatter.formatShort(selectedStartDate)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.emi),
              onPressed: () async {
                final total = double.tryParse(amountController.text.trim()) ?? 0;
                final months = int.tryParse(installmentsController.text.trim()) ?? 0;
                final name = nameController.text.trim();

                if (name.isEmpty || total <= 0 || months <= 0) return;

                final monthlyEmi = total / months;
                final planId = uuid.v4();
                final schedule = EMIPlanModel.generatePaymentSchedule(
                  emiPlanId: planId,
                  startDate: selectedStartDate,
                  numberOfInstallments: months,
                  monthlyAmount: monthlyEmi,
                );

                final plan = EMIPlanModel(
                  id: planId,
                  purchaseName: name,
                  totalAmount: total,
                  numberOfInstallments: months,
                  startDate: selectedStartDate,
                  monthlyEmiAmount: monthlyEmi,
                  category: 'emi_expense',
                  payments: schedule,
                  createdAt: DateTime.now(),
                );

                await repo.addEmiPlan(plan);
                Navigator.pop(ctx);
              },
              child: const Text('Create Plan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = Get.find<FinanceRepository>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EMI & Loan Planner', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'New EMI Plan',
            icon: const Icon(Icons.add, color: AppColors.emi),
            onPressed: () => _showNewEmiDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        final plans = repo.emiPlans;

        if (plans.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.credit_card_off, size: 64, color: AppColors.lightTextMuted),
                const SizedBox(height: 16),
                const Text('No EMI Plans Created', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 6),
                const Text('Track purchases with 3, 6, 12, or 24-month installments.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.emi),
                  onPressed: () => _showNewEmiDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Create First EMI Plan'),
                ),
              ],
            ),
          );
        }

        final totalRemainingLiability = plans.fold(0.0, (sum, p) => sum + p.remainingAmount);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: context.pagePadding,
              children: [
                // Top Liability Overview
                Container(
                  padding: EdgeInsets.all(context.isMobileSmall ? 12 : 18),
                  decoration: BoxDecoration(
                    color: AppColors.emi.withOpacity(0.1),
                    border: Border.all(color: AppColors.emi.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Outstanding Liability',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.emi),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                CurrencyFormatter.format(totalRemainingLiability),
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.isMobileSmall ? 20 : 24),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.emi,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${plans.length} Active',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // List of EMI Plans
                ...plans.map((plan) {
                  final progress = plan.numberOfInstallments > 0
                      ? plan.paidInstallments / plan.numberOfInstallments
                      : 0.0;
                  final nextDate = plan.nextEmiDate;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.emi.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.shopping_bag, color: AppColors.emi, size: 22),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                plan.purchaseName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                            if (plan.isCompleted)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'COMPLETED',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '${CurrencyFormatter.format(plan.monthlyEmiAmount)} / month • ${plan.paidInstallments} of ${plan.numberOfInstallments} paid',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                color: AppColors.emi,
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Remaining: ${CurrencyFormatter.format(plan.remainingAmount)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (nextDate != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    'Next: ${DateFormatter.formatShort(nextDate)}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.emi),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        children: [
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Installment Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                TextButton.icon(
                                  icon: const Icon(Icons.delete, size: 16, color: AppColors.danger),
                                  label: const Text('Delete Plan', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete EMI Plan'),
                                        content: Text('Delete "${plan.purchaseName}" and its linked transactions?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                                            onPressed: () {
                                              repo.deleteEmiPlan(plan.id);
                                              Navigator.pop(ctx);
                                            },
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          ...plan.payments.map((payment) {
                            final isSmall = context.isMobileSmall;
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 16),
                              leading: Icon(
                                payment.isPaid ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: payment.isPaid ? AppColors.success : AppColors.emi,
                                size: 18,
                              ),
                              title: Text(
                                'Installment ${payment.installmentNumber} of ${plan.numberOfInstallments}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isSmall ? 12 : 13,
                                  decoration: payment.isPaid ? TextDecoration.lineThrough : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                'Due ${DateFormatter.formatShort(payment.dueDate)} ${payment.paidDate != null ? '• Paid ${DateFormatter.formatShort(payment.paidDate!)}' : ''}',
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: payment.isPaid ? Colors.green : AppColors.emi,
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical:payment.isPaid ? 6 : 12),
                                  minimumSize: Size.zero,
                                ),
                                onPressed: () async {
                                  await repo.toggleEmiPaymentStatus(
                                    emiPlanId: plan.id,
                                    paymentId: payment.id,
                                  );
                                },
                                child: Text(
                                  payment.isPaid ? 'Paid ✓' : 'Mark Paid',
                                  style: const TextStyle(fontSize: 12, color: Colors.white),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 60),
              ],
            ),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_emi',
        backgroundColor: AppColors.emi,
        foregroundColor: Colors.white,
        onPressed: () => _showNewEmiDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New EMI Plan'),
      ),
    );
  }
}
