import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme.dart';

/// Remembers the child's preferred appearance between launches.
class ThemeService extends GetxService {
  ThemeService._(this._preferences, bool darkMode) : isDark = darkMode.obs;

  static const String _storageKey = 'dark_mode_enabled';

  final SharedPreferences _preferences;
  final RxBool isDark;

  static Future<ThemeService> load() async {
    final preferences = await SharedPreferences.getInstance();
    return ThemeService._(
      preferences,
      preferences.getBool(_storageKey) ?? false,
    );
  }

  Future<void> setDark(bool value) async {
    if (isDark.value == value) return;
    isDark.value = value;

    // GetMaterialApp keeps its own material controller. Rebuilding the app
    // alone does not replace that cached ThemeData, so update it explicitly.
    try {
      Get.changeTheme(AppTheme.build(dark: value));
    } catch (_) {
      // The app may not be mounted yet (for example in a unit test).
    }

    await _preferences.setBool(_storageKey, value);
  }

  Future<void> toggle() => setDark(!isDark.value);
}
