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
  final RenderController renderController =
      RenderController(logLevel: LogLevel.debug);

  @override
  void initState() {
    init = ExampleAnimationController.create(this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    init.then((value) => print("done"));
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
                      final stream = renderController.captureMotionWithStream(
                        functionController.duration,
                        settings: const MotionSettings(
                          pixelRatio: 5,
                          frameRate: 30,
                        ),
                        logInConsole: true,
                        format: Mp4Format(audio: [
                          RenderAudio.url(
                            Uri.parse(
                                "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4"),
                          ),
                          /*
                          RenderAudio.url(
                            Uri.parse(
                                "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"),
                            startTime: 40,
                            endTime: 45.4365,
                          ),
                           */
                        ]),
                      );
                      setState(() {
                        functionController.attach(stream);
                      });
                      final result = await stream.firstWhere(
                          (event) => event.isResult || event.isFatalError);
                      if (result.isFatalError) return;
                      displayResult(result as RenderResult);
                    },
                    exampleAnimationController: functionController,
                    imageRenderCallback: () async {
                      final imageResult = await renderController.captureImage(
                        format: ImageFormat.png,
                        settings: const ImageSettings(pixelRatio: 3),
                      );
                      displayResult(imageResult);
                    },
                  ),
                ],
              ),
            );
          } else {
            return Center(
              child: Text(
                "Error loading: ${snapshot.error}",
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> displayResult(RenderResult result,
      [bool saveToGallery = false]) async {
    print("file path: ${result.output.path}");
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
