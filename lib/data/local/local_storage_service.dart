import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_tracker/core/constants/app_constants.dart';
import 'package:finance_tracker/data/models/app_settings_model.dart';
import 'package:finance_tracker/data/models/budget_model.dart';
import 'package:finance_tracker/data/models/category_model.dart';
import 'package:finance_tracker/data/models/emi_model.dart';
import 'package:finance_tracker/data/models/gold_model.dart';
import 'package:finance_tracker/data/models/recurring_model.dart';
import 'package:finance_tracker/data/models/saving_model.dart';
import 'package:finance_tracker/data/models/transaction_model.dart';

class LocalStorageService extends GetxService {
  late final SharedPreferences _prefs;

  Future<LocalStorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  // --- Transactions ---
  Future<void> saveTransactions(List<TransactionModel> items) async {
    final rawList = items.map((e) => e.toJson()).toList();
    await _prefs.setString(AppConstants.keyTransactions, jsonEncode(rawList));
  }

  List<TransactionModel> loadTransactions() {
    final raw = _prefs.getString(AppConstants.keyTransactions);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Categories ---
  Future<void> saveCategories(List<CategoryModel> items) async {
    final rawList = items.map((e) => e.toJson()).toList();
    await _prefs.setString(AppConstants.keyCategories, jsonEncode(rawList));
  }

  List<CategoryModel> loadCategories() {
    final raw = _prefs.getString(AppConstants.keyCategories);
    if (raw == null || raw.isEmpty) return CategoryModel.defaultCategories;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return CategoryModel.defaultCategories;
    }
  }

  // --- EMI Plans ---
  Future<void> saveEmiPlans(List<EMIPlanModel> items) async {
    final rawList = items.map((e) => e.toJson()).toList();
    await _prefs.setString(AppConstants.keyEmiPlans, jsonEncode(rawList));
  }

  List<EMIPlanModel> loadEmiPlans() {
    final raw = _prefs.getString(AppConstants.keyEmiPlans);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => EMIPlanModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Saving Goals ---
  Future<void> saveSavingGoals(List<SavingGoalModel> items) async {
    final rawList = items.map((e) => e.toJson()).toList();
    await _prefs.setString(AppConstants.keySavingGoals, jsonEncode(rawList));
  }

  List<SavingGoalModel> loadSavingGoals() {
    final raw = _prefs.getString(AppConstants.keySavingGoals);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => SavingGoalModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Savings Records ---
  Future<void> saveSavingsRecords(List<SavingRecordModel> items) async {
    final rawList = items.map((e) => e.toJson()).toList();
    await _prefs.setString(AppConstants.keySavingsRecords, jsonEncode(rawList));
  }

  List<SavingRecordModel> loadSavingsRecords() {
    final raw = _prefs.getString(AppConstants.keySavingsRecords);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => SavingRecordModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Gold Investments ---
  Future<void> saveGoldInvestments(List<GoldInvestmentModel> items) async {
    final rawList = items.map((e) => e.toJson()).toList();
    await _prefs.setString(AppConstants.keyGoldInvestments, jsonEncode(rawList));
  }

  List<GoldInvestmentModel> loadGoldInvestments() {
    final raw = _prefs.getString(AppConstants.keyGoldInvestments);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => GoldInvestmentModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Budgets ---
  Future<void> saveBudgets(List<BudgetModel> items) async {
    final rawList = items.map((e) => e.toJson()).toList();
    await _prefs.setString(AppConstants.keyBudgets, jsonEncode(rawList));
  }

  List<BudgetModel> loadBudgets() {
    final raw = _prefs.getString(AppConstants.keyBudgets);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => BudgetModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Recurring Rules ---
  Future<void> saveRecurringRules(List<RecurringRuleModel> items) async {
    final rawList = items.map((e) => e.toJson()).toList();
    await _prefs.setString(AppConstants.keyRecurringRules, jsonEncode(rawList));
  }

  List<RecurringRuleModel> loadRecurringRules() {
    final raw = _prefs.getString(AppConstants.keyRecurringRules);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => RecurringRuleModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- App Settings ---
  Future<void> saveSettings(AppSettingsModel settings) async {
    await _prefs.setString(AppConstants.keyAppSettings, jsonEncode(settings.toJson()));
  }

  AppSettingsModel loadSettings() {
    final raw = _prefs.getString(AppConstants.keyAppSettings);
    if (raw == null || raw.isEmpty) return const AppSettingsModel();
    try {
      return AppSettingsModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettingsModel();
    }
  }

  // --- Destructive Actions ---
  Future<void> clearAllData() async {
    await _prefs.remove(AppConstants.keyTransactions);
    await _prefs.remove(AppConstants.keyCategories);
    await _prefs.remove(AppConstants.keyEmiPlans);
    await _prefs.remove(AppConstants.keySavingGoals);
    await _prefs.remove(AppConstants.keySavingsRecords);
    await _prefs.remove(AppConstants.keyGoldInvestments);
    await _prefs.remove(AppConstants.keyBudgets);
    await _prefs.remove(AppConstants.keyRecurringRules);
  }

  // --- JSON Export & Import ---
  String exportFullBackupJson() {
    final map = {
      'app': AppConstants.appName,
      'version': AppConstants.appVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'transactions': jsonDecode(_prefs.getString(AppConstants.keyTransactions) ?? '[]'),
      'categories': jsonDecode(_prefs.getString(AppConstants.keyCategories) ?? '[]'),
      'emiPlans': jsonDecode(_prefs.getString(AppConstants.keyEmiPlans) ?? '[]'),
      'savingGoals': jsonDecode(_prefs.getString(AppConstants.keySavingGoals) ?? '[]'),
      'savingsRecords': jsonDecode(_prefs.getString(AppConstants.keySavingsRecords) ?? '[]'),
      'goldInvestments': jsonDecode(_prefs.getString(AppConstants.keyGoldInvestments) ?? '[]'),
      'budgets': jsonDecode(_prefs.getString(AppConstants.keyBudgets) ?? '[]'),
      'recurringRules': jsonDecode(_prefs.getString(AppConstants.keyRecurringRules) ?? '[]'),
      'settings': jsonDecode(_prefs.getString(AppConstants.keyAppSettings) ?? '{}'),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  Future<bool> restoreFullBackupJson(String jsonString) async {
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      if (map['transactions'] != null) {
        await _prefs.setString(AppConstants.keyTransactions, jsonEncode(map['transactions']));
      }
      if (map['categories'] != null) {
        await _prefs.setString(AppConstants.keyCategories, jsonEncode(map['categories']));
      }
      if (map['emiPlans'] != null) {
        await _prefs.setString(AppConstants.keyEmiPlans, jsonEncode(map['emiPlans']));
      }
      if (map['savingGoals'] != null) {
        await _prefs.setString(AppConstants.keySavingGoals, jsonEncode(map['savingGoals']));
      }
      if (map['savingsRecords'] != null) {
        await _prefs.setString(AppConstants.keySavingsRecords, jsonEncode(map['savingsRecords']));
      }
      if (map['goldInvestments'] != null) {
        await _prefs.setString(AppConstants.keyGoldInvestments, jsonEncode(map['goldInvestments']));
      }
      if (map['budgets'] != null) {
        await _prefs.setString(AppConstants.keyBudgets, jsonEncode(map['budgets']));
      }
      if (map['recurringRules'] != null) {
        await _prefs.setString(AppConstants.keyRecurringRules, jsonEncode(map['recurringRules']));
      }
      if (map['settings'] != null) {
        await _prefs.setString(AppConstants.keyAppSettings, jsonEncode(map['settings']));
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
