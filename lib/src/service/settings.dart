class CapturingSettings {
  /// The pixelRatio describes the scale between the logical pixels and the size
  /// of images or video frames captured. Specifying 1.0 will give you a 1:1
  /// mapping between logical pixels and the output pixels in the image.
  ///
  /// See [RenderRepaintBoundary](https://api.flutter.dev/flutter/rendering/RenderRepaintBoundary/toImage.html)
  /// for the underlying implementation.
  final double pixelRatio;

  /// The time out for processing captures. Note that the process timeout is not
  /// related to the whole process, but rather to each FFmpeg execution.
  /// Meaning that if there are many layers & and sub calculations in the format
  /// the timeout will only trigger for each operation.
  final Duration processTimeout;

  /// Frames per second
  /// The amount of frames that should be captured in capturing process. This
  /// setting only applies to formats that support motion.
  /// This frame rate is subject to slightly adjust according duration of
  /// rendering and is limited by the frame rate of the application (normal frame
  /// rate should be at about 60 FPS). Any higher frame rate than the
  /// application itself is not possible and will be capped to the application
  /// one.
  ///
  /// ! This frame rate therefore does not necessary equal to output file frame rate
  final int frameRate;

  /// Data class for storing render related settings.
  /// Setting the optimal settings is critical for a successfully capturing.
  /// Depending on the device different frame rate and capturing quality might
  /// result in a laggy application and render results. To prevent this
  /// it is important find leveled values and optionally computational scaling
  /// of the output format.
  const CapturingSettings({
    this.frameRate = 30,
    this.pixelRatio = 3,
    this.processTimeout = const Duration(minutes: 3),
  }) : assert(frameRate < 100, "Frame rate unrealistic high.");
}

class EndCapturingSettings extends CapturingSettings {
  /// The duration of the capturing.
  final Duration capturingDuration;

  /// The amount of frames that are captured.
  final int frameAmount;

  ///The settings after capturing. This class hold the actual frame rate and and
  /// duration and might vary slightly from targeted settings.
  EndCapturingSettings({
    required super.pixelRatio,
    required super.processTimeout,
    required this.capturingDuration,
    required this.frameAmount,
  });

  /// In frames per second
  double get realFrameRate =>
      frameAmount / (capturingDuration.inMilliseconds / 1000);
}
