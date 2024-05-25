import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'animated_example_controller.dart';

class AnimatedExampleWidget extends StatefulWidget {
  final ExampleAnimationController exampleAnimationController;

  const AnimatedExampleWidget(
      {Key? key, required this.exampleAnimationController})
      : super(key: key);

  @override
  State<AnimatedExampleWidget> createState() => _AnimatedExampleWidgetState();
}

class _AnimatedExampleWidgetState extends State<AnimatedExampleWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: Colors.orange,
              child: AnimatedBuilder(
                animation: widget.exampleAnimationController.colorAnimation,
                builder: (context, child) {
                  return Container(
                    height: 100,
                    width: 100,
                    color:
                        widget.exampleAnimationController.colorAnimation.value,
                  );
                },
              ),
            ),
              SizedBox(
                height: 100,
                width: 100,
                child: VideoPlayer(
                    widget.exampleAnimationController.videoController!),
              ),
          ],
        ),
      ),
    );
  }
}
