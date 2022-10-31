import 'package:flutter/material.dart';
import 'package:render/src/service.dart';

class Render extends StatefulWidget {
  final Duration duration;
  final int frameRate;
  final Widget Function(RenderSnapshot snapshot) builder;

  Render({Key? key, required Widget child})
      : builder = ((snapshot) => child),
        duration = const Duration(seconds: 1),
        frameRate = 1,
        super(key: key);

  const Render.frames({
    Key? key,
    required this.duration,
    required this.frameRate,
    required this.builder,
  }) : super(key: key);

  @override
  State<Render> createState() => _RenderState();
}

class _RenderState extends State<Render> {
  int currentFrame = 0;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentFrame < snapshot.numberOfFrames) {
        setState(() {
          currentFrame++;
        });
      }
    });
    return widget.builder(snapshot);
  }

  RenderSnapshot get snapshot => RenderSnapshot(
        frame: currentFrame,
        duration: widget.duration,
        frameRate: widget.frameRate,
      );
}
