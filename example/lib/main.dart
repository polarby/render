import 'package:example/animated_example_widget.dart';
import 'package:example/animated_example_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:render/render.dart';
import 'animated_example_controller.dart';
import 'animated_example_popup.dart';
import 'package:screenshot/screenshot.dart';

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
  final ScreenshotController screenshotController = ScreenshotController();

  final GlobalKey renderKey = GlobalKey();

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
                  /*
                  Render(
                    controller: renderController,
                    builder: (BuildContext context, RenderSnapshot snapshot) {
                      if (snapshot.renderState == RenderState.rendering) {
                        functionController.videoController
                            .seekTo(snapshot.activity!.seekDuration);
                        //animationController.animateTo(target)
                      }
                      return AnimatedExampleWidget(
                        exampleAnimationController: functionController,
                      );
                    },
                  ),

                   */
                  Screenshot(
                    controller: screenshotController,
                    child: AnimatedExampleWidget(
                      exampleAnimationController: functionController,
                    ),
                  ),
                  const Spacer(),
                  NavigationButtons(
                    renderCallback: () async {
                      /*
                      final file = await renderController.capture(
                        RenderSettings(
                          duration:
                              functionController.videoController.value.duration,
                          frameRate: 10,
                        ),
                      );

                       */
                      print("render widget");
                      final bytes = await screenshotController.capture();
                      showDialog(
                        context: context,
                        builder: (BuildContext context) => AnimatedExamplePopUp(
                          context: context,
                          imageBytes: bytes,
                        ),
                      );
                    },
                    exampleAnimationController: functionController,
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
