import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    return MaterialApp(
      title: 'Su Terazisi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(
          0xFF0F172A,
        ), // Modern derin lacivert
      ),
      home: const LevelPage(),
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
  List<Map<String, dynamic>> savedAngles = [];
  StreamSubscription? _subscription;

  double _smoothX = 0;
  double _smoothY = 0;
  final double _filterFactor = 0.15;

  @override
  void initState() {
    super.initState();
    _subscription = accelerometerEventStream().listen((event) {
      _smoothX = _smoothX + (event.x - _smoothX) * _filterFactor;
      // [DÜZELTME] Y eksenini tersine çevirerek baloncuğun fiziksel doğruluğunu sağlıyoruz.
      // Fiziksel bir su terazisinde baloncuk her zaman en yüksek noktaya gider.
      double correctedY = -event.y;
      _smoothY = _smoothY + (correctedY - _smoothY) * _filterFactor;
      _sensorData.value = Offset(_smoothX, _smoothY);
    });
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.menu),
      ),
      appBar: AppBar(
        title: const Text(
          "PRO SU TERAZİSİ",
          style: TextStyle(letterSpacing: 2, fontSize: 14),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
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

              // Ana daire sınırları
              double mainLimit = (mainLevelSize / 2) - 22;
              double mainPosX = (x * 20).clamp(-mainLimit, mainLimit);
              double mainPosY = (y * 20).clamp(-mainLimit, mainLimit);

              // Tüp sınırları
              double tubeLimit = (mainLevelSize / 2) - 35;
              double tubePosX = (x * 15).clamp(-tubeLimit, tubeLimit);
              double tubePosY = (y * 15).clamp(-tubeLimit, tubeLimit);

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- YATAY TÜP (X Derecesi İçin) ---
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
                        // --- ANA MERKEZİ DAİRE ---
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: mainLevelSize,
                              height: mainLevelSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black26,
                                border: Border.all(
                                  color: isAllCentered
                                      ? Colors.green
                                      : Colors.white10,
                                  width: 2,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: mainLevelSize,
                              height: mainLevelSize,
                              child: CustomPaint(
                                painter: CrossLinesPainter(isAllCentered),
                              ),
                            ),
                            Transform.translate(
                              offset: Offset(mainPosX, mainPosY),
                              child: _buildSimpleBubble(44, isAllCentered),
                            ),
                          ],
                        ),

                        const SizedBox(width: 30),

                        // --- DİKEY TÜP (Y Derecesi İçin) ---
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

                    Text(
                      isAllCentered ? "MÜKEMMEL HİZALAMA" : "DÜZLEMİ AYARLAYIN",
                      style: TextStyle(
                        color: isAllCentered ? Colors.green : Colors.white38,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.5,
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

  // Su Terazisi Tüpü (Vial) Tasarımı
  Widget _buildVial({
    required double width,
    required double height,
    required double posX,
    required double posY,
    required double degree,
    required bool isCentered,
    required bool isHorizontal,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(
          color: isCentered ? Colors.green.withOpacity(0.5) : Colors.white10,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Orta işaret çizgisi
          isHorizontal
              ? Container(width: 2, height: height, color: Colors.white10)
              : Container(width: width, height: 2, color: Colors.white10),

          // Hareket eden derece baloncuğu
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
                      ? [Colors.greenAccent, Colors.green.shade800]
                      : [
                          Colors.white.withOpacity(0.9),
                          Colors.blueAccent.shade700,
                        ],
                  center: const Alignment(-0.3, -0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 8,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: RotatedBox(
                quarterTurns: isHorizontal ? 0 : 1,
                child: Text(
                  "${degree.abs().toStringAsFixed(1)}°",
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
    );
  }

  // Ana Seviye İçin Basit Baloncuk
  Widget _buildSimpleBubble(double size, bool isCentered) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: isCentered
              ? [Colors.greenAccent, Colors.green.shade800]
              : [Colors.white, Colors.blueAccent],
          center: const Alignment(-0.3, -0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: const Offset(2, 4),
          ),
        ],
      ),
    );
  }
}

class CrossLinesPainter extends CustomPainter {
  final bool isCentered;
  CrossLinesPainter(this.isCentered);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isCentered ? Colors.green.withOpacity(0.3) : Colors.white10
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
      oldDelegate.isCentered != isCentered;
}
