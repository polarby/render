import 'package:example/animated_example_widget.dart';
import 'package:example/animated_example_buttons.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:render/render.dart';
import 'animated_example_controller.dart';
import 'animated_example_popup.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late final Future<ExampleAnimationController> init;
  final RenderController renderController = RenderController();

  //final ScreenRecorderController screenRecorderController = ScreenRecorderController(pixelRatio: 5);

  @override
  void initState() {
    init = ExampleAnimationController.create(this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Render Example"),
      ),
      body: FutureBuilder(
        future: init,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            final functionController = snapshot.data!;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Spacer(),
                  Render(
                    controller: renderController,
                    child: AnimatedExampleWidget(
                      exampleAnimationController: functionController,
                    ),
                  ),
                  const Spacer(),
                  NavigationButtons(
                    motionRenderCallback: () async {
                      print(
                          "render widget, duration: ${functionController.videoController.value.duration}");
                      print(
                          "total frames: ${100 * functionController.videoController.value.duration.inSeconds}");

                      functionController.play();
                      final resultStream =
                          renderController.captureMotionWithStream(
                        functionController.videoController.value.duration,
                        const MotionSettings(frameRate: 1, pixelRatio: 5),
                      );

                      resultStream.stream.listen((event) {
                        if (event.isActivity) {
                          final activity = event as RenderActivity;
                          print("RenderActivity: ${activity.message} - "
                              "${activity.state.name}, time remaining:"
                              " ${activity.timeRemaining}, percentage:"
                              " ${activity.progressPercentage}");
                        }
                      });
                      final resultNotifier = await resultStream.stream
                          .firstWhere((element) => element.isResult);
                      final result = resultNotifier as RenderResult;
                      print(
                          "Finished export: totalTime: ${result.totalRenderTime}");
                      print("file exits: ${await result.output.exists()}");
                      if (mounted) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) =>
                              AnimatedExamplePopUp(
                            context: context,
                            //video: result,
                            imageBytes: result.output.readAsBytesSync(),
                          ),
                        );
                      }
                      await GallerySaver.saveImage(result.output.path);
                      print("saved export to gallery");
                    },
                    exampleAnimationController: functionController,
                    imageRenderCallback: () {},
                  ),
                ],
              ),
            );
          } else {
            return Text("Error");
          }
        },
      ),
    );
  }
}
