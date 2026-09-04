import 'package:get/get.dart';
import 'package:finance_tracker/data/models/emi_model.dart';
import 'package:finance_tracker/data/models/transaction_model.dart';
import 'package:finance_tracker/data/repositories/finance_repository.dart';

class DashboardController extends GetxController {
  final FinanceRepository repo = Get.find<FinanceRepository>();

  final currentMonth = DateTime.now().month.obs;
  final currentYear = DateTime.now().year.obs;

  void nextMonth() {
    if (currentMonth.value == 12) {
      currentMonth.value = 1;
      currentYear.value++;
    } else {
      currentMonth.value++;
    }
  }

  void previousMonth() {
    if (currentMonth.value == 1) {
      currentMonth.value = 12;
      currentYear.value--;
    } else {
      currentMonth.value--;
    }
  }

  void resetToCurrentMonth() {
    currentMonth.value = DateTime.now().month;
    currentYear.value = DateTime.now().year;
  }

  DateTime get selectedDate => DateTime(currentYear.value, currentMonth.value, 1);

  // Computed metrics for selected month
  double get monthIncome =>
      repo.getTotalIncome(month: currentMonth.value, year: currentYear.value);

  double get monthExpense =>
      repo.getTotalExpenses(month: currentMonth.value, year: currentYear.value);

  double get monthEmi =>
      repo.getTotalEmiPaid(month: currentMonth.value, year: currentYear.value);

  double get monthSavings =>
      repo.getTotalSavingsAllocated(month: currentMonth.value, year: currentYear.value);

  double get monthGold =>
      repo.getTotalGoldInvested(month: currentMonth.value, year: currentYear.value);

  double get monthAvailableBalance =>
      repo.getAvailableBalance(month: currentMonth.value, year: currentYear.value);

  double get allTimeBalance => repo.allTimeAvailableBalance;
  double get totalNetWorth => repo.totalNetWorth;

  List<TransactionModel> get recentTransactions {
    final list = List<TransactionModel>.from(repo.transactions);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list.take(6).toList();
  }

  List<EMIPaymentModel> get upcomingEmis {
    return repo.upcomingEmiPayments.take(3).toList();
  }

  Map<String, double> get categoryExpensesMap {
    final map = <String, double>{};
    for (final tx in repo.transactions) {
      if (tx.type == TransactionType.expense &&
          tx.date.month == currentMonth.value &&
          tx.date.year == currentYear.value) {
        final cat = repo.getCategoryById(tx.categoryId).name;
        map[cat] = (map[cat] ?? 0.0) + tx.amount;
      }
    }
    return map;
  }
}
