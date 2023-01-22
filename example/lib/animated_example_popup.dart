import 'package:flutter/material.dart';
import 'package:render/render.dart';
import 'package:video_player/video_player.dart';

class AnimatedExamplePopUp extends StatelessWidget {
  final BuildContext context;
  final RenderResult result;

  const AnimatedExamplePopUp({
    Key? key,
    required this.result,
    required this.context,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Render result'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          result.format.handling.isVideo
              ? FutureBuilder(future: () async {
                  final controller = VideoPlayerController.file(result.output);
                  controller.initialize();
                  controller.setLooping(true);
                  controller.play();
                  return controller;
                }(), builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.connectionState == ConnectionState.done) {
                    return Expanded(child: VideoPlayer(snapshot.data!));
                  } else {
                    return const Text("Error loading file");
                  }
                })
              : Expanded(child: Image.file(result.output)),
          const Divider(
            thickness: 5,
          ),
          Text(
            "Total render time: ${result.totalRenderTime.inMinutes}:"
            "${result.totalRenderTime.inSeconds}:"
            "${result.totalRenderTime.inMilliseconds}\n"
            "Format: ${result.format.extension}\n"
            "Capturing duration: ${result.usedSettings.capturingDuration}",
            textAlign: TextAlign.start,
          ),
        ],
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
