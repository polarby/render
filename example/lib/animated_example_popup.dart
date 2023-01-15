import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AnimatedExamplePopUp extends StatelessWidget {
  final BuildContext context;
  final File? video;
  final Uint8List? imageBytes;

  const AnimatedExamplePopUp({
    Key? key,
    this.video,
    this.imageBytes,
    required this.context,
  })  : assert(video != null || imageBytes != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Render result'),
      content: video != null
          ? FutureBuilder(future: () async {
              final VideoPlayerController controller =
                  VideoPlayerController.file(video!);
              await Future.delayed(const Duration(milliseconds: 300));
              await controller.initialize();
              await controller.play();
              return controller;
            }(), builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.connectionState == ConnectionState.done) {
                return VideoPlayer(snapshot.data!);
              } else {
                return Text("Error loading file");
              }
            })
          : Center(
              child: Image.memory(imageBytes!),
            ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(this.context).pop();
          },
          child: const Text('Great!'),
        ),
      ],
    );
  }
}
