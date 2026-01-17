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
        scaffoldBackgroundColor: const Color(0xFF121212),
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
  // [ADIM 1 & 4] Performans için ValueNotifier ve Modern API kullanımı
  final ValueNotifier<Offset> _sensorData = ValueNotifier(Offset.zero);
  StreamSubscription? _subscription;

  // [ADIM 2] Yumuşatma (Smoothing) için filtre değişkenleri
  double _smoothX = 0;
  double _smoothY = 0;
  final double _filterFactor = 0.15; // Değer düştükçe hareket daha yumuşak olur

  @override
  void initState() {
    super.initState();
    // [ADIM 4] accelerometerEventStream kullanımı
    _subscription = accelerometerEventStream().listen((event) {
      // [ADIM 2] Low-pass filter (Alçak geçiren filtre) uygulaması
      _smoothX = _smoothX + (event.x - _smoothX) * _filterFactor;
      _smoothY = _smoothY + (event.y - _smoothY) * _filterFactor;

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
      appBar: AppBar(
        title: const Text("Su Terazisi"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Ekran boyutuna göre dinamik çap belirleme
          double size = min(constraints.maxWidth, constraints.maxHeight) * 0.8;

          // [ADIM 1] Sadece değişen içeriği dinlemek için builder
          return ValueListenableBuilder<Offset>(
            valueListenable: _sensorData,
            builder: (context, offset, child) {
              double x = offset.dx;
              double y = offset.dy;

              // Hassasiyet ve derece hesaplamaları
              bool isCentered = (x.abs() < 0.5 && y.abs() < 0.5);
              double xDeg = atan2(x, 9.8) * 180 / pi;
              double yDeg = atan2(y, 9.8) * 180 / pi;

              // [ADIM 3] Sınır Kontrolü (Clamping)
              // Baloncuğu daire içinde tutar, dışarı taşmasını engeller
              double limit = (size / 2) - 20; // 20: baloncuğun yarıçapı payı
              double posX = (x * 20).clamp(-limit, limit);
              double posY = (y * 20).clamp(-limit, limit);

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${xDeg.toStringAsFixed(1)}°",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Dış Halkası
                            Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isCentered
                                      ? Colors.green
                                      : Colors.white24,
                                  width: 4,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            // Kılavuz Çizgiler (CustomPainter)
                            SizedBox(
                              width: size,
                              height: size,
                              child: CustomPaint(
                                painter: CrossLinesPainter(isCentered),
                              ),
                            ),
                            // Hareketli Baloncuk
                            Transform.translate(
                              offset: Offset(posX, posY),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isCentered
                                      ? Colors.green
                                      : Colors.redAccent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(2, 4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Text(
                          "${yDeg.toStringAsFixed(1)}°",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Text(
                      "X: ${x.toStringAsFixed(2)} | Y: ${y.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isCentered ? "MÜKEMMEL" : "EĞİM VAR",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isCentered ? Colors.green : Colors.redAccent,
                        letterSpacing: 1.2,
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
}

class CrossLinesPainter extends CustomPainter {
  final bool isCentered;
  CrossLinesPainter(this.isCentered);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isCentered ? Colors.green.withOpacity(0.5) : Colors.white10
      ..strokeWidth = 2;

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

    // [ADIM 5] Temiz ve şık bir orta hedef halkası
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      15,
      paint..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CrossLinesPainter oldDelegate) =>
      oldDelegate.isCentered != isCentered;
}
