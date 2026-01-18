import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  final _keyMode = 'themeMode'; // 0: System, 1: Light, 2: Dark
  final _keyColor = 'primaryColor';

  final RxInt themeModeIndex = 0.obs;
  // Rx<Color> olarak açıkça tanımlıyoruz, böylece Color ataması yapılabilir.
  final Rx<Color> primaryColor = Rx<Color>(Colors.blue);

  final List<Color> availableColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.amber,
  ];

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  ThemeMode get theme => _getThemeMode();

  ThemeMode _getThemeMode() {
    switch (themeModeIndex.value) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    themeModeIndex.value = prefs.getInt(_keyMode) ?? 0;

    // Kayıtlı rengi al, yoksa varsayılan mavi
    int colorValue = prefs.getInt(_keyColor) ?? Colors.blue.value;
    primaryColor.value = Color(colorValue); // Artık hata vermeyecek

    Get.changeThemeMode(theme);
  }

  void changeThemeMode(int index) async {
    themeModeIndex.value = index;
    Get.changeThemeMode(theme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMode, index);
  }

  void changePrimaryColor(Color color) async {
    primaryColor.value = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyColor, color.value);
  }

  bool get isDarkMode {
    if (themeModeIndex.value == 0) {
      return Get.isPlatformDarkMode;
    }
    return themeModeIndex.value == 2;
  }
}
