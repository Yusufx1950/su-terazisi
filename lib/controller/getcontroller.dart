import 'dart:convert';

import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AngleController extends GetxController {
  var savedAngles = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadFromDevice();

    // Liste değiştiğinde otomatik kaydet
    ever(savedAngles, (_) => _saveToDevice());
  }

  void addAngle(double xDeg, double yDeg, {String note = ""}) {
    savedAngles.add({"xDeg": xDeg, "yDeg": yDeg, "note": note});
  }

  void editAngle(int index, {String? note}) {
    if (index >= 0 && index < savedAngles.length) {
      savedAngles[index]["note"] = note ?? savedAngles[index]["note"];
      savedAngles.refresh();
    }
  }

  void deleteAngle(int index) {
    if (index >= 0 && index < savedAngles.length) {
      savedAngles.removeAt(index);
    }
  }

  Future<void> _saveToDevice() async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(savedAngles);
    await prefs.setString('angles', jsonString);
  }

  Future<void> _loadFromDevice() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('angles');
    if (jsonString != null) {
      List<dynamic> decoded = jsonDecode(jsonString);
      savedAngles.assignAll(decoded.cast<Map<String, dynamic>>());
    }
  }

  /// 📤 Tüm listeyi düz metin olarak paylaş
  void shareAllAngles() {
    if (savedAngles.isNotEmpty) {
      // Her açı için satır oluştur
      final buffer = StringBuffer();
      for (var i = 0; i < savedAngles.length; i++) {
        final angle = savedAngles[i];
        buffer.writeln(
          "Açı ${i + 1}: xDeg = ${angle['xDeg']}°, yDeg = ${angle['yDeg']}°, Not = ${angle['note']}",
        );
      }

      // Düz metin olarak paylaş
      Share.share(buffer.toString());
    } else {
      Share.share("Henüz kayıtlı açı yok.");
    }
  }
}
