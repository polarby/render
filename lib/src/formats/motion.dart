import 'package:render/src/formats/service.dart';

import 'abstract.dart';

class MovFormat extends MotionFormat {
  /// MOV (QuickTime File Format) is a file format that is used to store video
  /// and audio data. It is a popular format for storing high-quality video and
  /// is often used in professional video editing and production. MOV files can
  /// contain multiple video and audio tracks, as well as various metadata and
  /// other information. They can be played on a variety of devices and
  /// platforms, including Mac and Windows computers, iOS and Android devices,
  /// and many other media players.
  const MovFormat({
    super.audio,
    super.scale,
    super.interpolation = Interpolation.bicubic,
  }) : super(
          handling: FormatHandling.video,
          processShare: 0.2,
        );

  @override
  MovFormat copyWith({
    RenderScale? scale,
    Interpolation? interpolation,
  }) {
    return MovFormat(
      scale: scale ?? this.scale,
      interpolation: interpolation ?? this.interpolation,
    );
  }

  @override
  String get extension => "mov";
}

class GifFormat extends MotionFormat {
  /// If this format should render transparency.
  ///
  /// Transparency is a very expensive option, therefore it is only
  /// recommended for renderings which have a **dynamic changing transparency**
  /// or are very short.
  ///
  /// If you render only requires a static transparency it is recommended
  /// to apply those changes after the rendering process to the output video
  /// by using video editing tools like
  /// [Ffmpeg](https://pub.dev/packages/ffmpeg_kit_flutter).
  ///
  /// Alternatively you can also use [WebpFormat], which handles transparency
  /// way quicker.
  final bool transparency;

  /// If the gif should loop indefinitely
  final bool loop;

  /// GIF (Graphics Interchange Format) is a file format that is used to create
  /// animated images. It supports a limited color palette (up to 256 colors)
  /// and is typically used for small, simple animations or short loops. GIFs are
  /// typically smaller in file size than other video formats, making them well
  /// -suited for web use.
  const GifFormat({
    this.loop = true,
    this.transparency = false,
  }) : super(
          handling: FormatHandling.image,
          processShare: 0.2,
          scale: null,
          audio: null,
          // Scaling is not supported for gif, as there is no significant improvement when using it.
          interpolation: Interpolation.bicubic,
        );

  @override
  GifFormat copyWith({
    RenderScale? scale,
    Interpolation? interpolation,
    bool? transparency,
    bool? loop,
  }) {
    return GifFormat(
      loop: loop ?? this.loop,
      transparency: transparency ?? this.transparency,
    );
  }

  @override
  String get extension => "gif";

  @override
  FFmpegRenderOperation processor({
    required String inputPath,
    required String outputPath,
    required double frameRate,
  }) {
    return FFmpegRenderOperation([
      "-y",
      "-i", inputPath, // retrieve  captures
      transparency
          ? "-filter_complex??[0:v] setpts=N/($frameRate*TB),"
              "palettegen=stats_mode=single:max_colors=256 [palette];"
              " [0:v][palette] paletteuse"
          : "-filter:v??setpts=N/($frameRate*TB)",
      loop ? "-loop??0" : "-loop??-1",
      outputPath, // write output file
    ]);
  }
}

class Mp4Format extends MotionFormat {
  /// MP4 (MPEG-4 Part 14) is a digital multimedia container format most
  /// commonly used to store video and audio, but can also be used to store
  /// other data such as subtitles and still images. It is a standard format
  /// used by many devices and platforms to play videos, and is known for
  /// its high compression rate and good quality. MP4 files typically have
  /// the file extension ".mp4".
  /// Transparency is not supported.
  const Mp4Format({
    super.audio,
    super.scale,
    super.interpolation = Interpolation.bicubic,
  }) : super(
          handling: FormatHandling.video,
          processShare: 0.2,
        );

  @override
  Mp4Format copyWith({
    RenderScale? scale,
    Interpolation? interpolation,
  }) {
    return Mp4Format(
      scale: scale ?? this.scale,
      interpolation: interpolation ?? this.interpolation,
    );
  }

  @override
  String get extension => "mp4";
}
