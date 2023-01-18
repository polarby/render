import 'dart:io';

import 'package:render/src/formats.dart';

/// Data class for storing render related settings
class RenderSettings {
  /// The pixelRatio describes the scale between the logical pixels and the size
  /// of images or video frames captured. Specifying 1.0 will give you a 1:1
  /// mapping between logical pixels and the output pixels in the image.
  ///
  /// See [RenderRepaintBoundary](https://api.flutter.dev/flutter/rendering/RenderRepaintBoundary/toImage.html)
  /// for the underlying implementation.
  final double pixelRatio;

  const RenderSettings({
    this.pixelRatio = 3,
  });
}

class MotionSettings extends RenderSettings {
  /// Frames per second
  /// This frame rate is subject to slightly adjust according duration of
  /// rendering and is limited by the frame rate of the application (normal frame
  /// rate should be at about 60 FPS). Any higher frame rate than the
  /// application itself is not possible and will be capped to the application
  /// one.
  final int frameRate;

  /// Output format
  /// The format that the widget should be rendered to. Return value will be
  /// a [File] with the selected file type and properties.
  final MotionFormat format;

  /// If the render should support transparency.
  /// Only applicable to file formats that support transparency.
  ///
  /// Transparency is a very expensive option, that dramatically lengthens
  /// render time; the current process requires to create a transparency
  /// mask of every frame and later applying it to the render itself. This
  /// process almost doubles the processing time and is therefore only
  /// recommended for renderings which have a **dynamic changing transparency**
  /// or are very short. For every other render please follow the alternative
  /// below:
  ///
  /// ### Alternative: Static transparency
  /// If your render only requires a static transparency (no change of position
  /// of the transparency, eg. transparent rounded corners), it is recommended
  /// to apply those changes after the rendering process to the output video
  /// by using video editing tools like [Ffmpeg](https://pub.dev/packages/ffmpeg_kit_flutter).
  final bool transparency;

  const MotionSettings({
    this.format = MotionFormat.gif,
    this.frameRate = 30,
    this.transparency = false,
    super.pixelRatio,
  });
}

class ImageSettings extends RenderSettings {
  /// Output format
  /// The format that the widget should be rendered to. Return value will be
  /// a [File] with the selected file type and properties.
  final ImageFormat format;

  const ImageSettings({
    this.format = ImageFormat.png,
    super.pixelRatio,
  });
}
