import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:render/render.dart';
import 'package:video_player/video_player.dart';

class ExampleAnimationController extends ChangeNotifier {
  final AnimationController animationController;
  final Animation colorAnimation;
  final Animation<int> positionAnimation;
  final VideoPlayerController? videoController;
  Stream<RenderNotifier>? renderStream;

  ExampleAnimationController({
    required TickerProvider vsync,
    required this.videoController,
    required this.animationController,
    required this.colorAnimation,
    required this.positionAnimation,
  }) {
    animationController.addListener(() {
      if (animationController.status == AnimationStatus.completed) {
        animationController.reset();
        videoController?.seekTo(const Duration(microseconds: 0));
        videoController?.pause();
        notifyListeners();
      }
    });
  }

  void attach(Stream<RenderNotifier> stream) {
    renderStream = stream;
  }

  static Future<ExampleAnimationController> create(TickerProvider vsync) async {
    VideoPlayerController? videoController;
    if (!Platform.isMacOS) {
       videoController = VideoPlayerController.network(
        'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
        // 1 min: https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4
        // 4 sec: 'https://www.fluttercampus.com/video.mp4'
      );
       await videoController.initialize();
    }
    final animationController = AnimationController(
        vsync: vsync,
        duration:
            videoController?.value.duration ?? const Duration(seconds: 4));
    final colorAnimation = ColorTween(begin: Colors.blue, end: Colors.yellow)
        .animate(animationController);
    final positionAnimation =
        IntTween(begin: 0, end: 50).animate(animationController);
    return ExampleAnimationController(
      vsync: vsync,
      positionAnimation: positionAnimation,
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
    videoController?.play();
  }
}
