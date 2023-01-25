import 'package:flutter/material.dart';
import 'package:render/render.dart';
import 'package:video_player/video_player.dart';

class AnimatedExamplePopUp extends StatelessWidget {
  final BuildContext context;
  final RenderResult result;
  VideoPlayerController? controller;

  AnimatedExamplePopUp({
    Key? key,
    required this.result,
    required this.context,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Render result'),
      content: result.format.handling.isVideo
          ? FutureBuilder(future: () async {
              controller = VideoPlayerController.file(result.output);
              await controller!.initialize();
              await controller!.setLooping(true);
              controller!.play();
              return controller;
            }(), builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.data != null) {
                return Column(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: snapshot.data?.value.size.width ?? 0,
                          height: snapshot.data?.value.size.height ?? 0,
                          child: VideoPlayer(snapshot.data!),
                        ),
                      ),
                    ),
                    VideoProgressIndicator(
                      snapshot.data!,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        backgroundColor: Colors.red,
                        bufferedColor: Colors.black,
                        playedColor: Colors.blueAccent,
                      ),
                    ),
                    const Divider(
                      thickness: 1,
                    ),
                    Text(
                      "Total render time: ${result.totalRenderTime.inMinutes}:"
                      "${result.totalRenderTime.inSeconds}:"
                      "${result.totalRenderTime.inMilliseconds}\n"
                      "Format: ${result.format.extension}\n"
                      "Video duration: ${controller?.value.duration}\n"
                      "Size: ${result.output.lengthSync() / 1000000} MB",
                      textAlign: TextAlign.start,
                    ),
                  ],
                );
              } else {
                return Center(
                  child: Text(
                    "Error loading file: ${snapshot.error}",
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),
                );
              }
            })
          : Column(
              children: [
                Expanded(child: Image.file(result.output)),
                const Divider(
                  thickness: 2,
                ),
                Text(
                  "Total render time: ${result.totalRenderTime.inMinutes}:"
                  "${result.totalRenderTime.inSeconds}:"
                  "${result.totalRenderTime.inMilliseconds}\n"
                  "Format: ${result.format.extension}\n"
                  "Size: ${result.output.lengthSync() / 1000000} MB",
                  textAlign: TextAlign.start,
                ),
              ],
            ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            controller?.pause();
            controller?.dispose();
            Navigator.of(this.context).pop();
          },
          child: const Text('Great!'),
        ),
      ],
    );
  }
}
