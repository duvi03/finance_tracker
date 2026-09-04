import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:finance_tracker/app/routes/app_routes.dart';
import 'package:finance_tracker/app/theme/app_theme.dart';
import 'package:finance_tracker/core/constants/app_constants.dart';
import 'package:finance_tracker/data/repositories/finance_repository.dart';

class ArthaApp extends StatelessWidget {
  const ArthaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = Get.find<FinanceRepository>();

    return Obx(() {
      final themeMode = repo.settings.value.themeMode;

      return GetMaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.main,
        getPages: AppRoutes.pages,
      );
    });
  }
}
