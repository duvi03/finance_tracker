import 'package:flutter/material.dart';

class AppSettingsModel {
  final String currencySymbol;
  final String currencyCode;
  final ThemeMode themeMode;
  final bool hasInitializedDefaults;

  const AppSettingsModel({
    this.currencySymbol = '₹',
    this.currencyCode = 'INR',
    this.themeMode = ThemeMode.system,
    this.hasInitializedDefaults = false,
  });

  AppSettingsModel copyWith({
    String? currencySymbol,
    String? currencyCode,
    ThemeMode? themeMode,
    bool? hasInitializedDefaults,
  }) {
    return AppSettingsModel(
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyCode: currencyCode ?? this.currencyCode,
      themeMode: themeMode ?? this.themeMode,
      hasInitializedDefaults: hasInitializedDefaults ?? this.hasInitializedDefaults,
    );
  }

  Map<String, dynamic> toJson() => {
        'currencySymbol': currencySymbol,
        'currencyCode': currencyCode,
        'themeMode': themeMode.name,
        'hasInitializedDefaults': hasInitializedDefaults,
      };

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    final themeName = json['themeMode'] as String? ?? 'system';
    final theme = ThemeMode.values.firstWhere(
      (e) => e.name == themeName,
      orElse: () => ThemeMode.system,
    );
    return AppSettingsModel(
      currencySymbol: json['currencySymbol'] as String? ?? '₹',
      currencyCode: json['currencyCode'] as String? ?? 'INR',
      themeMode: theme,
      hasInitializedDefaults: json['hasInitializedDefaults'] as bool? ?? false,
    );
  }
}
