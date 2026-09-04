import 'package:get/get.dart';
import 'package:finance_tracker/features/shell/views/main_shell_view.dart';

class AppRoutes {
  static const main = '/';
  static const dashboard = '/dashboard';

  static final pages = [
    GetPage(
      name: main,
      page: () => const MainShellView(),
    ),
    GetPage(
      name: dashboard,
      page: () => const MainShellView(),
    ),
  ];
}
