import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:get/get.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:su_terazisi/pages/liste_duzen.dart';

import 'controller/getcontroller.dart';
import 'controller/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Controller'ları başlat
  Get.put(ThemeController());
  Get.put(AngleController());

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const LevelApp());
  });
}

class LevelApp extends StatelessWidget {
  const LevelApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(
      () => GetMaterialApp(
        title: 'Su Terazisi',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: themeController.primaryColor.value,
          brightness: Brightness.light,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: themeController.primaryColor.value,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        themeMode: themeController.theme,
        home: const LevelPage(),
      ),
    );
  }
}

class LevelPage extends StatefulWidget {
  const LevelPage({super.key});

  @override
  State<LevelPage> createState() => _LevelPageState();
}

class _LevelPageState extends State<LevelPage> {
  final ValueNotifier<Offset> _sensorData = ValueNotifier(Offset.zero);
  StreamSubscription? _subscription;
  final AngleController angleController = Get.find<AngleController>();
  final ThemeController themeController = Get.find<ThemeController>();

  double _smoothX = 0;
  double _smoothY = 0;
  final double _filterFactor = 0.15;

  @override
  void initState() {
    super.initState();
    _subscription = accelerometerEventStream().listen((event) {
      _smoothX = _smoothX + (event.x - _smoothX) * _filterFactor;
      double correctedY = -event.y;
      _smoothY = _smoothY + (correctedY - _smoothY) * _filterFactor;
      _sensorData.value = Offset(_smoothX, _smoothY);
    });
  }

  void _showSaveDialog(double x, double y) {
    final TextEditingController noteController = TextEditingController();

    // Temel açılar
    double baseXDeg = atan2(x, 9.8) * 180 / pi;
    double baseYDeg = atan2(y, 9.8) * 180 / pi;

    // UI ile uyumlu olması için 2 ile çarpılmış değerler
    double xDeg = baseXDeg * 2;
    double yDeg = baseYDeg * 2;

    Get.defaultDialog(
      title: "Açıyı Kaydet",
      backgroundColor: themeController.isDarkMode
          ? const Color(0xFF1E293B)
          : Colors.white,
      titleStyle: TextStyle(
        color: themeController.isDarkMode ? Colors.white : Colors.black,
      ),
      content: Column(
        children: [
          Text(
            "X: ${xDeg.toStringAsFixed(1)}° | Y: ${yDeg.toStringAsFixed(1)}°",
            style: TextStyle(
              color: themeController.primaryColor.value,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: noteController,
            style: TextStyle(
              color: themeController.isDarkMode ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              labelText: "Not Ekle (Opsiyonel)",
              labelStyle: TextStyle(
                color: themeController.isDarkMode
                    ? Colors.white70
                    : Colors.black54,
              ),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      textConfirm: "KAYDET",
      textCancel: "İPTAL",
      confirmTextColor: Colors.white,
      onConfirm: () {
        angleController.addAngle(xDeg, yDeg, note: noteController.text);
        Get.back();
        Get.snackbar(
          "Başarılı",
          "Açı kaydedildi.",
          snackPosition: SnackPosition.TOP,
          backgroundColor: themeController.primaryColor.value.withValues(
            alpha: 0.7,
          ),
          colorText: Colors.white,
        );
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _sensorData.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Obx(
              () => DrawerHeader(
                decoration: BoxDecoration(
                  color: themeController.primaryColor.value,
                ),
                child: const Text(
                  "Ayarlar",
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                "Tema Modu",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Obx(
              () => Column(
                children: [
                  Radio<int>(
                    value: 0,
                    groupValue: themeController.themeModeIndex.value,
                    onChanged: (v) => themeController.changeThemeMode(v!),
                  ),
                  const Text("Sistem"),
                  Radio<int>(
                    value: 1,
                    groupValue: themeController.themeModeIndex.value,
                    onChanged: (v) => themeController.changeThemeMode(v!),
                  ),
                  const Text("Aydınlık"),
                  Radio<int>(
                    value: 2,
                    groupValue: themeController.themeModeIndex.value,
                    onChanged: (v) => themeController.changeThemeMode(v!),
                  ),
                  const Text("Karanlık"),
                ],
              ),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                "Vurgu Rengi",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(
                () => Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: themeController.availableColors.map((color) {
                    return GestureDetector(
                      onTap: () => themeController.changePrimaryColor(color),
                      child: CircleAvatar(
                        backgroundColor: color,
                        radius: 18,
                        child: themeController.primaryColor.value == color
                            ? const Icon(
                                Icons.check,
                                size: 20,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Obx(
        () => SpeedDial(
          icon: Icons.add,
          activeIcon: Icons.close,
          backgroundColor: themeController.primaryColor.value,
          children: [
            SpeedDialChild(
              child: const Icon(Icons.save),
              label: 'Kaydet',
              onTap: () {
                final offset = _sensorData.value;
                _showSaveDialog(offset.dx, offset.dy);
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.edit),
              label: 'Tüm Liste',
              onTap: () => Get.to(() => const Kaydedilenler()),
            ),
            SpeedDialChild(
              child: const Icon(Icons.delete),
              label: 'Listeyi Sil',
              onTap: () {
                if (angleController.savedAngles.isNotEmpty) {
                  angleController.deleteAngle(
                    angleController.savedAngles.length - 1,
                  );
                  Get.snackbar(
                    "Silindi",
                    "Son kayıt silindi.",
                    snackPosition: SnackPosition.TOP,
                  );
                }
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text(
          "PRO SU TERAZİSİ",
          style: TextStyle(letterSpacing: 2, fontSize: 14),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double mainLevelSize =
              min(constraints.maxWidth, constraints.maxHeight) * 0.65;
          double tubeThickness = 60.0;

          return ValueListenableBuilder<Offset>(
            valueListenable: _sensorData,
            builder: (context, offset, child) {
              double x = offset.dx;
              double y = offset.dy;

              bool isXCentered = x.abs() < 0.5;
              bool isYCentered = y.abs() < 0.5;
              bool isAllCentered = isXCentered && isYCentered;

              double xDeg = atan2(x, 9.8) * 180 / pi;
              double yDeg = atan2(y, 9.8) * 180 / pi;

              double mainLimit = (mainLevelSize / 2) - 22;
              double mainPosX = (x * 20).clamp(-mainLimit, mainLimit);
              double mainPosY = (y * 20).clamp(-mainLimit, mainLimit);

              double tubeLimit = (mainLevelSize / 2) - 35;
              double tubePosX = (x * 15).clamp(-tubeLimit, tubeLimit);
              double tubePosY = (y * 15).clamp(-tubeLimit, tubeLimit);

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildVial(
                      width: mainLevelSize,
                      height: tubeThickness,
                      posX: tubePosX,
                      posY: 0,
                      degree: xDeg,
                      isCentered: isXCentered,
                      isHorizontal: true,
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Obx(
                              () => Container(
                                width: mainLevelSize,
                                height: mainLevelSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: themeController.isDarkMode
                                      ? Colors.black26
                                      : Colors.grey[300],
                                  border: Border.all(
                                    color: isAllCentered
                                        ? themeController.primaryColor.value
                                        : (themeController.isDarkMode
                                              ? Colors.white10
                                              : Colors.black12),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: mainLevelSize,
                              height: mainLevelSize,
                              child: Obx(
                                () => CustomPaint(
                                  painter: CrossLinesPainter(
                                    isAllCentered,
                                    themeController.primaryColor.value,
                                  ),
                                ),
                              ),
                            ),
                            Transform.translate(
                              offset: Offset(mainPosX, mainPosY),
                              child: _buildSimpleBubble(44, isAllCentered),
                            ),
                          ],
                        ),
                        const SizedBox(width: 30),
                        _buildVial(
                          width: tubeThickness,
                          height: mainLevelSize,
                          posX: 0,
                          posY: tubePosY,
                          degree: yDeg,
                          isCentered: isYCentered,
                          isHorizontal: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),
                    Obx(
                      () => Text(
                        isAllCentered
                            ? "MÜKEMMEL HİZALAMA"
                            : "DÜZLEMİ AYARLAYIN",
                        style: TextStyle(
                          color: isAllCentered
                              ? themeController.primaryColor.value
                              : (themeController.isDarkMode
                                    ? Colors.white38
                                    : Colors.black38),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildVial({
    required double width,
    required double height,
    required double posX,
    required double posY,
    required double degree,
    required bool isCentered,
    required bool isHorizontal,
  }) {
    return Obx(
      () => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: themeController.isDarkMode ? Colors.black38 : Colors.grey[400],
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(
            color: isCentered
                ? themeController.primaryColor.value.withValues(alpha: 0.5)
                : (themeController.isDarkMode
                      ? Colors.white10
                      : Colors.black12),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            isHorizontal
                ? Container(
                    width: 2,
                    height: height,
                    color: themeController.isDarkMode
                        ? Colors.white10
                        : Colors.black12,
                  )
                : Container(
                    width: width,
                    height: 2,
                    color: themeController.isDarkMode
                        ? Colors.white10
                        : Colors.black12,
                  ),
            Transform.translate(
              offset: Offset(posX, posY),
              child: Container(
                width: isHorizontal ? 65 : 45,
                height: isHorizontal ? 45 : 65,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: RadialGradient(
                    colors: isCentered
                        ? [Colors.white, themeController.primaryColor.value]
                        : [
                            Colors.white.withValues(alpha: 0.9),
                            themeController.primaryColor.value.withValues(
                              alpha: 0.7,
                            ),
                          ],
                    center: const Alignment(-0.3, -0.3),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 8,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: RotatedBox(
                  quarterTurns: isHorizontal ? 0 : 1,
                  child: Text(
                    "${(degree.abs() * 2).toStringAsFixed(1)}°",
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleBubble(double size, bool isCentered) {
    return Obx(
      () => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: isCentered
                ? [Colors.white, themeController.primaryColor.value]
                : [
                    Colors.white,
                    themeController.primaryColor.value.withValues(alpha: 0.7),
                  ],
            center: const Alignment(-0.3, -0.3),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(2, 4),
            ),
          ],
        ),
      ),
    );
  }
}

class CrossLinesPainter extends CustomPainter {
  final bool isCentered;
  final Color primaryColor;
  CrossLinesPainter(this.isCentered, this.primaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final themeController = Get.find<ThemeController>();
    final paint = Paint()
      ..color = isCentered
          ? primaryColor.withValues(alpha: 0.3)
          : (themeController.isDarkMode ? Colors.white10 : Colors.black12)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      20,
      paint..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CrossLinesPainter oldDelegate) =>
      oldDelegate.isCentered != isCentered ||
      oldDelegate.primaryColor != primaryColor;
}
