import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ExampleAnimationController extends ChangeNotifier {
  final AnimationController animationController;
  final Animation colorAnimation;
  final VideoPlayerController videoController;

  ExampleAnimationController({
    required TickerProvider vsync,
    required this.videoController,
    required this.animationController,
    required this.colorAnimation,
  }) {
    animationController.addListener(() {
      if (animationController.status == AnimationStatus.completed) {
        animationController.reset();
        videoController.seekTo(const Duration(microseconds: 0));
        notifyListeners();
      }
    });
  }

  static Future<ExampleAnimationController> create(TickerProvider vsync) async {
    final videoController = VideoPlayerController.network(
      'https://www.fluttercampus.com/video.mp4',
    );
    await videoController.initialize();
    final animationController = AnimationController(
        vsync: vsync, duration: videoController.value.duration);
    final colorAnimation = ColorTween(begin: Colors.blue, end: Colors.yellow)
        .animate(animationController);
    return ExampleAnimationController(
      vsync: vsync,
      videoController: videoController,
      animationController: animationController,
      colorAnimation: colorAnimation,
    );
  }

  set value(double newValue) => animationController.value = newValue;

  double get value => animationController.value;

  Duration get duration => animationController.duration!;

  double get process => animationController.value;

  void play() {
    animationController.forward();
    videoController.play();
  }
}
