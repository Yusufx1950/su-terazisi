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
      appBar: AppBar(title: Text('saved_measurements'.tr)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => angleController.shareAllAngles(),
        child: const Icon(Icons.share),
      ),
      body: Obx(() {
        if (angleController.savedAngles.isEmpty) {
          return Center(
            child: Text(
              'no_measurements'.tr,
              style: TextStyle(
                fontSize: 18,
                color: context.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.5,
                ),
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        } else {
          return ListView.builder(
            itemCount: angleController.savedAngles.length,
            itemBuilder: (context, index) {
              final angle = angleController.savedAngles[index];
              return AngleListItem(
                key: ValueKey(index),
                angle: angle,
                index: index,
                controller: angleController,
              );
            },
          );
        }
      }),
    );
  }
}

class AngleListItem extends StatefulWidget {
  final Map<String, dynamic> angle;
  final int index;
  final AngleController controller;

  const AngleListItem({
    super.key,
    required this.angle,
    required this.index,
    required this.controller,
  });

  @override
  State<AngleListItem> createState() => _AngleListItemState();
}

class _AngleListItemState extends State<AngleListItem> {
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.angle["note"] ?? "");
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.save, color: Colors.green),
        title: Text(
          "X: ${widget.angle["xDeg"].toStringAsFixed(1)}°, "
          "Y: ${widget.angle["yDeg"].toStringAsFixed(1)}°",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: TextField(
          controller: _noteController,
          decoration: InputDecoration(
            hintText: 'enter_note'.tr,
            border: InputBorder.none,
          ),
          onChanged: (value) {
            widget.controller.editAngle(widget.index, note: value);
          },
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () => widget.controller.deleteAngle(widget.index),
        ),
      ),
    );
  }
}
