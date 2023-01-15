import 'package:flutter/material.dart';
import 'animated_example_controller.dart';

class NavigationButtons extends StatelessWidget {
  final VoidCallback renderCallback;
  final ExampleAnimationController exampleAnimationController;

  const NavigationButtons({
    Key? key,
    required this.renderCallback,
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
                  renderCallback();
                },
                child: const Text("Capture")),
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
