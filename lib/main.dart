import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:finance_tracker/app/app.dart';
import 'package:finance_tracker/data/local/local_storage_service.dart';
import 'package:finance_tracker/data/repositories/finance_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline local storage
  final storageService = await LocalStorageService().init();
  Get.put<LocalStorageService>(storageService);

  // Initialize finance repository
  Get.put<FinanceRepository>(FinanceRepository());

  runApp(const ArthaApp());
}
