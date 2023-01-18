import 'package:flutter/material.dart';
import 'animated_example_controller.dart';

class NavigationButtons extends StatelessWidget {
  final void Function() motionRenderCallback;
  final void Function() imageRenderCallback;
  final ExampleAnimationController exampleAnimationController;

  const NavigationButtons({
    Key? key,
    required this.imageRenderCallback,
    required this.motionRenderCallback,
    required this.exampleAnimationController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
            animation: exampleAnimationController.colorAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: exampleAnimationController.process,
              );
            }),
        Wrap(
          children: [
            TextButton(
                onPressed: () {
                  motionRenderCallback();
                },
                child: const Text("Capture motion")),
            TextButton(
                onPressed: () {
                  imageRenderCallback();
                },
                child: const Text("Capture image")),
            TextButton(
                onPressed: () {
                  exampleAnimationController.play();
                },
                child: const Text("Play"))
          ],
        ),
      ],
    );
  }
}
