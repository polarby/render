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
                      functionController.play();
                      final resultStream =
                          renderController.captureMotionWithStream(
                        functionController.videoController.value.duration,
                        capturingSettings: const CapturingSettings(
                            pixelRatio: 5, frameRate: 20),
                        format: MovFormat(
                          audio: [

                            RenderAudio.url(
                              Uri.parse(
                                'https://www.fluttercampus.com/video.mp4',
                              ),
                            ),
                          ],
                        ),
                      );
                      setState(() {
                        functionController.attach(resultStream);
                      });
                      final resultNotifier = await resultStream
                          .firstWhere((element) => element.isResult);
                      final result = resultNotifier as RenderResult;
                      displayResult(result);
                    },
                    exampleAnimationController: functionController,
                    imageRenderCallback: () async {
                      final resultStream =
                          renderController.captureImageWithStream(
                        format: ImageFormat.png,
                        capturingSettings: CapturingSettings(pixelRatio: 10),
                      );
                      setState(() {
                        functionController.attach(resultStream);
                      });
                      final resultNotifier = await resultStream
                          .firstWhere((element) => element.isResult);
                      final result = resultNotifier as RenderResult;
                      displayResult(result);
                    },
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

  Future<void> displayResult(RenderResult result,
      [bool saveToGallery = false]) async {
    print("file exits: ${await result.output.exists()}");
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AnimatedExamplePopUp(
          context: context,
          result: result,
        ),
      );
    }
    if (saveToGallery) {
      GallerySaver.saveImage(result.output.path)
          .then((value) => print("saved export to gallery"));
    }
  }
}
