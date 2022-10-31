class RenderSnapshot {
  final int frameRate;
  final Duration duration;
  final int frame;

  RenderSnapshot({
    required this.duration,
    required this.frameRate,
    required this.frame,
  });

  int get numberOfFrames => frameRate * (duration.inSeconds);
}

enum RenderState {
  rendering,
  done,
  none,
}
