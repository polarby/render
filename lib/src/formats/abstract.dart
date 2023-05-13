import 'package:render/src/formats/image.dart';
import 'package:render/src/formats/service.dart';

import 'motion.dart';

abstract class RenderFormat {
  /// How the format can be handled. This is important for handling the file later
  /// (eg. displaying the file). Some file types might be [FormatType.motion] but
  /// still should be handled like an image (eg. apng, gif, etc.).
  final FormatHandling handling;

  /// The percentage of the main process execution time of the whole render
  /// operation. This value is determined by experimentation.
  ///
  /// Example:
  /// If the [processShare] is 0.5, it means that the main processing time will
  /// take 50% of the render time to finish. Meaning that if the capturing time
  /// is 2min the expected processing time will also be 2min.
  ///
  /// Note that sub-render tasks are not considered in this
  /// value and will be calculated separately, but based on this value.
  final double processShare;

  /// Interpolation in is a method used to calculate new pixel values
  /// when resizing images. It is used to make sure that the resulting image
  /// looks as smooth and natural as possible. Different interpolation methods
  /// are available, each with its own trade-offs in terms of quality and
  /// computational expense.
  ///
  /// Interpolation will only be used if [scale] is specified.
  final Interpolation interpolation;

  /// Scaling frames in video processing refers to the process of resizing the
  /// frames of a video to a different resolution. This is done to adjust the
  /// size of the video to match the resolution of the target device or medium.
  final RenderScale? scale;

  /// A class that defines the format of the output file.
  const RenderFormat({
    required this.scale,
    required this.handling,
    required this.processShare,
    required this.interpolation,
  });

  /// The extension of this file format (eg. "png") Note that this format needs
  /// to be compatible with FFmpeg to work with processing.
  String get extension;

  /// The ffmpeg processing function for this format. The task is to convert
  /// png frame(s) to the exportable format.
  ///
  /// #### Parameters
  /// The function provides you with [inputPath] of the frames, which will have
  /// `/frame%d.png` structure or `/frame.png` depending on the format type.
  /// The [outputPath] is the path of the file that should be written to.
  /// Note that the output file will have the format type of [extension].
  ///
  /// The [frameRate] refers to the frame rate based on the amount of inputPath
  /// and duration of capturing.
  ///
  /// The [inputPath] directory is associated to the current session, and will
  /// be cleared after completion.
  ///
  /// #### Return
  /// The return of this function has to be a list of [FFmpegRenderOperation]s.
  /// In case that there are sub tasks you can pass multiple operations here.
  /// The asynchronous execution of those arguments will be in a synchronous
  /// sequence.
  ///
  /// Waiting time of processor will be treated as preparation time for
  /// processing (should not contain the main process)
  FFmpegRenderOperation processor({
    required String inputPath,
    required String outputPath,
    required double frameRate,
    required int width,
    required int height,
  });

  /// Scaling ffmpeg filter with appropriate interpolation integration
  /// While maintaing aspect ratio
  String? get scalingFilter =>
      scale != null ? "scale=w=${scale!.w}:-1:${interpolation.name}" : null;

  bool get isMotion => this is MotionFormat;

  bool get isImage => this is ImageFormat;

  MotionFormat? get asMotion => isMotion ? this as MotionFormat : null;

  ImageFormat? get asImage => isImage ? this as ImageFormat : null;
}

abstract class MotionFormat extends RenderFormat {
  /// Additional audio for the motion format (if supported by output format)
  /// Make sure that the audio file has the same length as the output video.
  ///
  /// If you provide multiple audios, it will takes the longest and will freeze
  /// video at the last frame, if the audio is exceeds the video duration.
  final List<RenderAudio>? audio;

  /// Formats that include some sort of motion and have multiple frames.
  const MotionFormat({
    required this.audio,
    required super.scale,
    required super.interpolation,
    required super.handling,
    required super.processShare,
  });

  /// A function that allows you to copy the format with new parameters.
  /// This is useful for creating a new format with the same base but different
  /// parameters. Alternatively you can call the Format directly (eg. [MovFormat]).
  MotionFormat copyWith({
    RenderScale? scale,
    Interpolation? interpolation,
  });

  /// Default motion processor. This can be override, if more/other settings are
  /// needed.
  @override
  FFmpegRenderOperation processor({
    required String inputPath,
    required String outputPath,
    required double frameRate,
    required int width,
    required int height,
  }) {
    final audioInput = audio != null && audio!.isNotEmpty
        ? audio!.map((e) => "-i??${e.path}").join('??')
        : null;
    final mergeAudiosList = audio != null && audio!.isNotEmpty
        ? ";${List.generate(audio!.length, (index) => "[${index + 1}:a]" // list audio
                "atrim=start=${audio![index].startTime}" // start time of audio
                ":${"end=${audio![index].endTime}"}[a${index + 1}];").join()}" // end time of audio
            "${List.generate(audio!.length, (index) => "[a${index + 1}]").join()}" // list audio
            "amix=inputs=${audio!.length}[a]" // merge audios
        : "";
    final overwriteAudioExecution =
        audio != null && audio!.isNotEmpty // merge audios with existing (none)
            ? "-map??[v]??-map??[a]??-c:v??libx264??-c:a??"
                "aac??-shortest??-pix_fmt??yuv420p??-vsync??2"
            : "-map??[v]??-pix_fmt??yuv420p";
    return FFmpegRenderOperation([
      "-f", "rawvideo", // input format
      "-pixel_format", "rgba", // input pixel format
      "-s", "${width}x${height}", // input size
      "-r", "$frameRate", // input frame rate
      "-i", inputPath, // retrieve  captures
      audioInput,
      "-filter_complex",
      "[0:v]${scalingFilter != null ? "$scalingFilter," : ""}"
          "setpts=N/($frameRate*TB)[v]$mergeAudiosList",
      overwriteAudioExecution,
      "-y",
      outputPath, // write output file
    ]);
  }

  static MovFormat get mov => const MovFormat();

  static Mp4Format get mp4 => const Mp4Format();

  static GifFormat get gif => const GifFormat();
}

abstract class ImageFormat extends RenderFormat {
  /// Formats that are static images with one single frame.
  const ImageFormat({
    required super.scale,
    required super.interpolation,
    required super.handling,
    required super.processShare,
  });

  /// A function that allows you to copy the format with new parameters.
  /// This is useful for creating a new format with the same base but different
  /// parameters. Alternatively you can call the Format directly (eg. [PngFormat]).
  ImageFormat copyWith({
    RenderScale? scale,
    Interpolation? interpolation,
  });

  /// Default image processor. This can be override, if more settings are
  /// needed.
  @override
  FFmpegRenderOperation processor({
    required String inputPath,
    required String outputPath,
    required double frameRate,
    required int width,
    required int height,
  }) {
    return FFmpegRenderOperation([
      "-y",
      "-f", "rawvideo",
      "-pixel_format", "rgba",
      "-s", "${width}x${height}",
      "-r", "$frameRate",
      "-i", inputPath, // input image
      scalingFilter != null ? "-vf??$scalingFilter" : null,
      "-vframes", "1", // indicate that there is only one frame
      outputPath,
    ]);
  }

  static ImageFormat get png => const PngFormat();

  static ImageFormat get jpg => const JpgFormat();

  static ImageFormat get bmp => const BmpFormat();

  static ImageFormat get tiff => const TiffFormat();
}
