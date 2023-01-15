import '../render.dart';

/// Data class for storing render related settings
class RenderSettings {
  ///Frames per second
  final int frameRate;

  ///If only pne frame should be captured [duration] will be 1 second and
  ///frameRate 1.
  final Duration duration;

  const RenderSettings({required this.duration, required this.frameRate});

  const RenderSettings.standard()
      : duration = const Duration(seconds: 1),
        frameRate = 1;

  int get numberOfFrames => frameRate * duration.inSeconds;
}

/// Data class that stores render related activity data. Meaning both
/// Render settings and data that actively changes during rendering.
class RenderActivity extends RenderSettings {
  /// The current frame of the render
  final int frame;

  RenderActivity({
    required this.frame,
    required super.duration,
    required super.frameRate,
  });

  RenderActivity.fromSettings({
    required this.frame,
    required RenderSettings settings,
  }) : super(duration: settings.duration, frameRate: settings.frameRate);

  RenderState get activeState =>
      hasEnded ? RenderState.done : RenderState.rendering;

  bool get hasEnded => frame >= numberOfFrames;

  double get animationJump => frame / numberOfFrames;

  Duration get seekDuration =>
      Duration(milliseconds: frame ~/ numberOfFrames * duration.inMilliseconds);

  @override
  String toString() {
    return "RenderActivity(frame: $frame)";
  }
}
