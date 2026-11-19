import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/core/constants/supabase_constants.dart';
import 'app/routes/app_pages.dart';
import 'app/bindings/initial_binding.dart';
import 'app/core/theme/app_theme.dart';
import 'app/services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  final themeService = await ThemeService.load();
  Get.put(themeService, permanent: true);

  runApp(MathClashApp(themeService: themeService));
}

class MathClashApp extends StatelessWidget {
  const MathClashApp({super.key, required this.themeService});

  final ThemeService themeService;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final theme = AppTheme.build(dark: themeService.isDark.value);
      return GetMaterialApp(
        title: 'MathClash',
        theme: theme,
        darkTheme: theme,
        themeMode: ThemeMode.light,
        initialBinding: InitialBinding(),
        getPages: AppPages.routes,
        initialRoute: AppPages.initial,
        debugShowCheckedModeBanner: false,
      );
    });
  }
}
