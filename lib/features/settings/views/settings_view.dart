import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:finance_tracker/core/constants/app_colors.dart';
import 'package:finance_tracker/core/constants/app_constants.dart';
import 'package:finance_tracker/core/utils/backup_file_manager.dart';
import 'package:finance_tracker/core/utils/responsive_utils.dart';
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
    final fileName = BackupFileManager.getBackupFileName();
    final isSmall = context.isMobileSmall;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.file_download, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Export JSON Backup',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Container(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description, color: AppColors.primary, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Backup File Name:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            fileName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.download, size: 20),
                label: Text(
                  'Download $fileName',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall ? 12 : 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: () async {
                  final success = await BackupFileManager.downloadBackupJson(jsonBackup);
                  if (context.mounted) {
                    Navigator.pop(ctx);
                  }
                  if (success) {
                    Get.snackbar(
                      'Download Started',
                      'Backup file saved as $fileName',
                      backgroundColor: AppColors.success,
                      colorText: Colors.white,
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy JSON to Clipboard'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: jsonBackup));
                  Get.snackbar(
                    'Copied',
                    'JSON backup copied to clipboard',
                    backgroundColor: AppColors.primary,
                    colorText: Colors.white,
                  );
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Raw JSON Preview:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
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
    final isSmall = context.isMobileSmall;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.file_upload, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Restore Data from Backup',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Container(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Select an Artha backup JSON file or paste its content to restore all records.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.file_open, size: 20),
                    label: Text(
                      'Choose Backup File (.json)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall ? 12 : 14),
                    ),
                    onPressed: () async {
                      final content = await BackupFileManager.pickAndReadBackupJson();
                      if (content != null && content.isNotEmpty) {
                        setDialogState(() {
                          importController.text = content;
                        });
                        Get.snackbar(
                          'File Loaded',
                          'Backup file loaded into field. Tap Restore to proceed.',
                          backgroundColor: AppColors.primary,
                          colorText: Colors.white,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'OR PASTE JSON',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: importController,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: 'Paste Artha JSON backup content here...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                final text = importController.text.trim();
                if (text.isEmpty) return;

                final success = await repo.restoreJsonBackup(text);
                if (context.mounted) {
                  Navigator.pop(ctx);
                }

                if (success) {
                  Get.snackbar(
                    'Success',
                    'Data restored successfully!',
                    backgroundColor: AppColors.success,
                    colorText: Colors.white,
                  );
                } else {
                  Get.snackbar(
                    'Error',
                    'Invalid JSON backup format',
                    backgroundColor: AppColors.danger,
                    colorText: Colors.white,
                  );
                }
              },
              child: const Text('Restore Backup'),
            ),
          ],
        ),
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
              padding: context.pagePadding,
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
                          isDense: true,
                          items: const [
                            DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                            DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                            DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
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
                          isDense: true,
                          items: const [
                            DropdownMenuItem(value: '₹', child: Text('₹ (INR)')),
                            DropdownMenuItem(value: '\$', child: Text('\$ (USD)')),
                            DropdownMenuItem(value: '€', child: Text('€ (EUR)')),
                            DropdownMenuItem(value: '£', child: Text('£ (GBP)')),
                            DropdownMenuItem(value: 'AED', child: Text('AED')),
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
                        subtitle: Text('Download ${BackupFileManager.getBackupFileName()}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showExportJsonDialog(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.file_upload, color: AppColors.primary),
                        title: const Text('Restore Data from Backup'),
                        subtitle: const Text('Choose an Artha backup JSON file or paste JSON'),
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
