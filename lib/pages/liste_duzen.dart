import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../controller/getcontroller.dart';

class Kaydedilenler extends StatefulWidget {
  const Kaydedilenler({super.key});

  @override
  State<Kaydedilenler> createState() => _KaydedilenlerState();
}

class _KaydedilenlerState extends State<Kaydedilenler> {
  void shareAngle(Map<String, dynamic> angle) {
    final text =
        "xDeg: ${angle['xDeg']}, yDeg: ${angle['yDeg']}, note: ${angle['note']}";
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final AngleController angleController = Get.find();

    return Scaffold(
      appBar: AppBar(title: const Text("Kaydedilen Ölçümler")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => angleController.shareAllAngles(),
        child: const Icon(Icons.share),
      ),
      body: Obx(() {
        if (angleController.savedAngles.isEmpty) {
          return Center(
            child: Text(
              "Henüz ölçüm kaydedilmedi",
              style: TextStyle(
                fontSize: 18,
                color: context.textTheme.bodyMedium?.color?.withOpacity(0.5),
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        } else {
          return ListView.builder(
            itemCount: angleController.savedAngles.length,
            itemBuilder: (context, index) {
              final angle = angleController.savedAngles[index];
              final noteController = TextEditingController(
                text: angle["note"] ?? "",
              );

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.save, color: Colors.green),
                  title: Text(
                    "X: ${angle["xDeg"].toStringAsFixed(1)}°, "
                    "Y: ${angle["yDeg"].toStringAsFixed(1)}°",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      hintText: "Not giriniz",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (value) {
                      angleController.editAngle(index, note: value);
                    },
                    onChanged: (value) {
                      angleController.editAngle(index, note: value);
                    },
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => angleController.deleteAngle(index),
                  ),
                ),
              );
            },
          );
        }
      }),
    );
  }
}
