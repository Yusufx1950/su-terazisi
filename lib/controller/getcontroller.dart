import 'package:get/get.dart';

class AngleController extends GetxController {
  // RxList ile reaktif liste
  var savedAngles = <Map<String, dynamic>>[].obs;

  void addAngle(double xDeg, double yDeg, {String note = ""}) {
    savedAngles.add({"xDeg": xDeg, "yDeg": yDeg, "note": note});
  }

  void editAngle(int index, {String? note}) {
    if (index >= 0 && index < savedAngles.length) {
      savedAngles[index]["note"] = note ?? savedAngles[index]["note"];
      savedAngles.refresh(); // UI güncellenir
    }
  }

  void deleteAngle(int index) {
    if (index >= 0 && index < savedAngles.length) {
      savedAngles.removeAt(index);
    }
  }
}
