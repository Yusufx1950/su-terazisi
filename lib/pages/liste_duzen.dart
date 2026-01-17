import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/getcontroller.dart';

class Kaydedilenler extends StatefulWidget {
  const Kaydedilenler({super.key});

  @override
  State<Kaydedilenler> createState() => _KaydedilenlerState();
}

class _KaydedilenlerState extends State<Kaydedilenler> {
  @override
  Widget build(BuildContext context) {
    final AngleController angleController = Get.find();

    return Scaffold(
      appBar: AppBar(title: const Text("Su Terazisi")),
      body: Obx(() {
        if (angleController.savedAngles.isEmpty) {
          // Liste boşsa ortada mesaj göster
          return const Center(
            child: Text(
              "Henüz ölçüm kaydedilmedi",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        } else {
          // Liste doluysa render et
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
                ),
              );
            },
          );
        }
      }),
    );
  }
}
