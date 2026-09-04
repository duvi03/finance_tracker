import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:finance_tracker/core/constants/app_colors.dart';
import 'package:finance_tracker/core/constants/app_constants.dart';
import 'package:finance_tracker/data/models/category_model.dart';
import 'package:finance_tracker/data/repositories/finance_repository.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  void _showAddCategoryDialog(BuildContext context) {
    final repo = Get.find<FinanceRepository>();
    final nameController = TextEditingController();
    CategoryType type = CategoryType.expense;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Custom Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Category Name', hintText: 'e.g. Subscriptions, Pet Care'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CategoryType>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: CategoryType.expense, child: Text('Expense')),
                  DropdownMenuItem(value: CategoryType.income, child: Text('Income')),
                  DropdownMenuItem(value: CategoryType.both, child: Text('Both')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => type = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final cat = CategoryModel(
                  id: name.toLowerCase().replaceAll(' ', '_'),
                  name: name,
                  iconCodePoint: Icons.label.codePoint,
                  colorValue: 0xFF6366F1,
                  type: type,
                  isCustom: true,
                );
                await repo.addCategory(cat);
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportJsonDialog(BuildContext context) {
    final repo = Get.find<FinanceRepository>();
    final jsonBackup = repo.exportJsonBackup();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('JSON Data Backup'),
        content: SizedBox(
          width: 500,
          height: 350,
          child: Column(
            children: [
              const Text(
                'Copy and save this JSON backup safely. You can paste it back at any time to restore your entire financial records.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      jsonBackup,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showImportJsonDialog(BuildContext context) {
    final repo = Get.find<FinanceRepository>();
    final importController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Data from JSON'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste your previously exported Artha JSON backup below. This will merge and restore your data.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: importController,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Paste JSON content here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final text = importController.text.trim();
              if (text.isEmpty) return;

              final success = await repo.restoreJsonBackup(text);
              Navigator.pop(ctx);

              if (success) {
                Get.snackbar('Success', 'Data restored successfully!', backgroundColor: AppColors.success, colorText: Colors.white);
              } else {
                Get.snackbar('Error', 'Invalid JSON backup format', backgroundColor: AppColors.danger, colorText: Colors.white);
              }
            },
            child: const Text('Restore Backup'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmDialog(BuildContext context) {
    final repo = Get.find<FinanceRepository>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Reset All Financial Data?'),
          ],
        ),
        content: const Text(
          'WARNING: This is permanent and cannot be undone. All your transactions, EMI plans, gold purchases, budgets, and savings goals will be deleted from your local device/browser storage.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              await repo.resetAllData();
              Navigator.pop(ctx);
              Get.snackbar('Data Cleared', 'All application data has been wiped.', backgroundColor: AppColors.danger, colorText: Colors.white);
            },
            child: const Text('Confirm Erase All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = Get.find<FinanceRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Backup', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Obx(() {
        final settings = repo.settings.value;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Warning Notice Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    border: Border.all(color: Colors.amber.shade700.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.security, color: Colors.amber.shade800, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '100% Offline & Private',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Artha stores all your data purely in your local browser/device storage. No account is required and no data is ever uploaded to a server. Remember to Export JSON backups periodically to protect your records.',
                              style: TextStyle(fontSize: 12, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Theme Section
                const Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.palette_outlined),
                        title: const Text('Theme Mode'),
                        trailing: DropdownButton<ThemeMode>(
                          value: settings.themeMode,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: ThemeMode.system, child: Text('System Default')),
                            DropdownMenuItem(value: ThemeMode.light, child: Text('Light Mode')),
                            DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark Mode')),
                          ],
                          onChanged: (mode) {
                            if (mode != null) {
                              repo.updateSettings(settings.copyWith(themeMode: mode));
                              Get.changeThemeMode(mode);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Currency Section
                const Text('Currency & Regional', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.currency_rupee),
                        title: const Text('Currency Symbol'),
                        trailing: DropdownButton<String>(
                          value: settings.currencySymbol,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: '₹', child: Text('₹ (INR - Indian Rupee)')),
                            DropdownMenuItem(value: '\$', child: Text('\$ (USD - Dollar)')),
                            DropdownMenuItem(value: '€', child: Text('€ (EUR - Euro)')),
                            DropdownMenuItem(value: '£', child: Text('£ (GBP - Pound)')),
                            DropdownMenuItem(value: 'AED', child: Text('AED (Dirham)')),
                          ],
                          onChanged: (sym) {
                            if (sym != null) {
                              repo.updateSettings(settings.copyWith(currencySymbol: sym));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Category Management
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Custom'),
                      onPressed: () => _showAddCategoryDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: repo.categories.map((cat) {
                        return Chip(
                          avatar: Icon(cat.icon, size: 16, color: cat.color),
                          label: Text(cat.name, style: const TextStyle(fontSize: 12)),
                          onDeleted: cat.isCustom ? () => repo.deleteCategory(cat.id) : null,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Data Backup & Restore
                const Text('Data Safety & Backup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.file_download, color: AppColors.primary),
                        title: const Text('Export JSON Backup'),
                        subtitle: const Text('Backup all transactions, EMIs, gold, and savings to a file'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showExportJsonDialog(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.file_upload, color: AppColors.primary),
                        title: const Text('Restore Data from Backup'),
                        subtitle: const Text('Restore records from a previously exported JSON backup'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showImportJsonDialog(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Destructive Reset
                const Text('Danger Zone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.danger)),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.delete_forever, color: AppColors.danger),
                    title: const Text('Clear All Application Data', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Permanently erase all local data from this device'),
                    onTap: () => _showResetConfirmDialog(context),
                  ),
                ),
                const SizedBox(height: 24),

                // App Info Footer
                Center(
                  child: Column(
                    children: [
                      Text(
                        '${AppConstants.appName} v${AppConstants.appVersion}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Offline-First Personal Finance & Wealth Tracker',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }),
    );
  }
}
