import 'package:flutter/material.dart';
import 'package:render/render.dart';
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: StreamBuilder<RenderNotifier>(
              stream: exampleAnimationController.renderStream
                  ?.where((event) => !event.isLog),
              builder: (context, snapshot) {
                if (snapshot.data?.isActivity == true &&
                    !snapshot.data!.isResult) {
                  final activity = snapshot.data as RenderActivity;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Render activity:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text("Operation: ${activity.state.name}"),
                      Text("Message: ${activity.message}"),
                      Text("TimeRemaining: ${activity.timeRemaining}"),
                      Text("TotalExpectedTime: ${activity.totalExpectedTime}"),
                      Text(
                          "ProgressPercentage: ${activity.progressPercentage * 100}%"),
                      Text("Current time: ${activity.timestamp}"),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: LinearProgressIndicator(
                          value: activity.progressPercentage,
                        ),
                      ),
                    ],
                  );
                } else if (snapshot.data?.isError == true) {
                  final error = snapshot.data as RenderError;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Render Error:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text("fatal: ${error.fatal}"),
                      Text("Message: ${error.exception.message}"),
                    ],
                  );
                } else {
                  return Container();
                }
              }),
        ),
        Center(
          child: Wrap(
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
        ),
      ],
    );
  }
}
