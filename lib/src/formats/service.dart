import 'dart:io';

/// Arguments associated for ffmpeg execution. Note, that calling "ffmpeg"
/// is not needed.
class FFmpegRenderOperation {
  final List<String> arguments;

  /// Takes ffmpeg arguments and null. Nulls will simply be converted to string.
  /// Will split arguments into two, if a `??` is found
  FFmpegRenderOperation(List<String?> arguments)
      : arguments = arguments
            .whereType<String>()
            .expand((element) => element.split("??"))
            .toList();
}

/// How the format can be handled. This is important for handling the file later
/// (eg. displaying the file). Some file types might be [FormatType.motion] but
/// still should be handled like an image (eg. apng, gif, etc.).
enum FormatHandling {
  /// Handling like an image (everything from png, jpeg to gif)
  image,

  ///Handling like a video (everything from mp4 to mov)
  video,

  /// Unknown handling are files that usually cannot be opened by a default
  /// image or video reader (eg. psd)
  unknown;

  bool get isVideo => this == FormatHandling.video;

  bool get isImage => this == FormatHandling.image;

  bool get isUnknown => this == FormatHandling.unknown;
}

class RenderScale {
  final int w;
  final int h;

  /// Scaling frames in video processing refers to the process of resizing the
  /// frames of a video to a different resolution. This is done to adjust the
  /// size of the video to match the resolution of the target device or medium.
  const RenderScale(this.w, this.h);

  static RenderScale get fullHD => const RenderScale(1920, 1080);

  static RenderScale get hd => const RenderScale(1280, 720);

  static RenderScale get fourK => const RenderScale(3840, 2160);

  static RenderScale get lowRes => const RenderScale(640, 360);

  static RenderScale get veryLowRes => const RenderScale(320, 180);

  static RenderScale get qhd => const RenderScale(2560, 1440);

  static RenderScale get svga => const RenderScale(800, 600);

  static RenderScale get xga => const RenderScale(1024, 768);

  static RenderScale get hdPlus => const RenderScale(1366, 768);

  static RenderScale get wqxga => const RenderScale(2560, 1600);
}

/// Interpolation in is a method used to calculate new pixel values
/// when resizing images. It is used to make sure that the resulting image
/// looks as smooth and natural as possible. Different interpolation methods
/// are available, each with its own trade-offs in terms of quality and
/// computational expense.
///
/// Interpolation will only be used if [scale] is specified.
enum Interpolation {
  /// Nearest-neighbor interpolation is a simple method that selects the
  /// color of the nearest pixel to the one being calculated. It is fast
  /// but produces aliasing and jagged edges. This method is very fast and
  /// it's recommended for cases where the resolution doesn't need to be
  /// very high or where the performance is critical.
  nearest,

  /// Bilinear interpolation is an extension of nearest-neighbor
  /// interpolation that takes the average color of the 4 nearest
  /// pixels. It produces better results than nearest-neighbor but
  /// it can still produce some jagged edges. This method is faster than
  /// bicubic and Lanczos interpolation and it's recommended for cases
  /// where the resolution needs to be higher than nearest-neighbor but
  /// the performance is still critical.
  bilinear,

  /// Bicubic interpolation is a more complex method that takes
  /// into account the 16 nearest pixels to the one being calculated.
  /// It produces smoother results than bilinear interpolation but
  /// it also requires more processing power. This method is slower than
  /// bilinear interpolation but faster than Lanczos and spline. It's
  /// recommended for cases where the resolution needs to be higher than
  /// bilinear and the performance can afford the extra calculation time.
  bicubic,

  /// Lanczos interpolation is a high-quality method that uses a
  /// Lanczos kernel to calculate the new pixel values. It produces
  /// the best results among all interpolation methods but it also
  /// requires the most processing power. This method is the slowest one
  /// and is recommended for cases where the quality is more important
  /// than the performance.
  lanczos,

  /// Spline interpolation is a method that uses a spline function
  /// to calculate the new pixel values. It produces good results
  /// but it's slower than bicubic interpolation. This method is slower
  /// than bicubic and faster than Lanczos interpolation. It's recommended
  /// for cases where the quality needs to be higher than bicubic but the
  /// performance can't afford Lanczos.
  spline,

  /// Gaussian interpolation is a method that uses a Gaussian kernel
  /// to calculate the new pixel values. It's similar to bicubic
  /// interpolation but it's not as widely supported. This method is
  /// similar in performance and quality to bicubic interpolation, but
  /// it's not as widely supported. It's recommended for cases where
  /// specific software or libraries are being used that support this
  /// method.
  gauss,

  /// Sinc interpolation is a method that uses a Sinc kernel
  /// to calculate the new pixel values. It's similar to Lanczos
  /// interpolation but it's not as widely supported. This method is
  /// similar in performance and quality to Lanczos interpolation, but
  /// it's not as widely supported. It's recommended for cases where
  /// specific software or libraries are being used that support this
  /// method.
  sinc,
}

class RenderAudio {
  /// The path to the audio source (must be compatible with ffmpeg source path)
  final String path;

  /// The start time in seconds
  final double startTime;

  /// The end time in seconds
  /// If the time exceeds the duration, it will crop at the end.
  final double endTime;

  /// Audio from a url source. This can also be a video format, where only the
  /// sound is being taken
  RenderAudio.url(Uri url, {this.startTime = 0, this.endTime = 1000})
      : path = url.toString();

  /// Audio from a File source. This can also be a video format, where only the
  /// sound is being taken
  RenderAudio.file(File file, {this.startTime = 0, this.endTime = 1000})
      : path = file.path;

  /// Duration of expected RenderAudio. Duration may not relate to the actual
  /// audio duration, as [endTime] can be specified arbitrarily
  Duration? get duration =>
      Duration(milliseconds: (endTime / 1000 - startTime / 1000).toInt());
}
