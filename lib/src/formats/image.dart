import '../../render.dart';

class PngFormat extends ImageFormat {
  /// PNG (Portable Network Graphics) is a lossless image format that supports
  /// transparent backgrounds and a wide range of colors. It is commonly used
  /// for web and graphic design projects due to its high quality and small
  /// file size.
  ///
  /// In Flutter, PNG images can be easily integrated and used within the
  /// application. The "Image" widget is commonly used to display PNG images,
  /// and they can also be used as background images or in buttons and other
  /// UI elements. Additionally, the "AssetImage" class can be used to load
  /// PNG images from the application's asset folder. Overall, the PNG
  /// format is a popular choice for Flutter developers due to its high
  /// quality and compatibility with the framework.
  const PngFormat({
    super.scale,
    super.interpolation = Interpolation.bicubic,
  }) : super(
          handling: FormatHandling.image,
          processShare: 0.5,
        );

  @override
  PngFormat copyWith({
    RenderScale? scale,
    Interpolation? interpolation,
  }) {
    return PngFormat(
      scale: scale ?? this.scale,
      interpolation: interpolation ?? this.interpolation,
    );
  }

  @override
  String get extension => "png";
}

class JpgFormat extends ImageFormat {
  /// JPG, also known as JPEG, is a popular image file format that is widely
  /// used for digital photos and images. It uses a compression method that
  /// reduces the size of the file without significantly affecting the
  /// quality of the image.
  /// Does not support transparency.
  const JpgFormat({
    super.scale,
    super.interpolation = Interpolation.bicubic,
  }) : super(
          handling: FormatHandling.image,
          processShare: 0.5,
        );

  @override
  JpgFormat copyWith({
    RenderScale? scale,
    Interpolation? interpolation,
  }) {
    return JpgFormat(
      scale: scale ?? this.scale,
      interpolation: interpolation ?? this.interpolation,
    );
  }

  @override
  String get extension => "jpg";
}

class BmpFormat extends ImageFormat {
  /// BMP (Bitmap) is a widely-used image file format that is primarily used
  /// on Microsoft Windows operating systems. It is a simple, uncompressed
  /// format that stores digital images in a grid of pixels. BMP files can be
  /// created and edited using various image editing software, and they can
  /// contain both monochrome and color images. Despite its age and lack of
  /// advanced features, BMP remains a popular format due to its compatibility
  /// with older systems and its ability to store large amounts of data in a
  /// single file.
  const BmpFormat({
    super.scale,
    super.interpolation = Interpolation.bicubic,
  }) : super(
          handling: FormatHandling.image,
          processShare: 0.5,
        );

  @override
  BmpFormat copyWith({
    RenderScale? scale,
    Interpolation? interpolation,
  }) {
    return BmpFormat(
      scale: scale ?? this.scale,
      interpolation: interpolation ?? this.interpolation,
    );
  }

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
      "-i", inputPath, // input image
      "-pix_fmt", "bgra",
      scalingFilter != null ? "-vf??$scalingFilter" : null,
      "-vframes", "1", // indicate that there is only one frame
      outputPath,
    ]);
  }

  @override
  String get extension => "bmp";
}

class TiffFormat extends ImageFormat {
  /// TIFF (Tagged Image File Format) is a widely used image file format that
  /// supports lossless compression and high-resolution images. It is commonly
  /// used in the printing and publishing industry due to its ability to
  /// maintain image quality while also allowing for editing and manipulation
  /// of the image. TIFF files can also include metadata, such as keywords
  /// and captions, making them useful for archiving and organizing digital
  /// images.
  ///
  /// It is not supported by flutters default image visualizer.
  const TiffFormat({
    super.scale,
    super.interpolation = Interpolation.bicubic,
  }) : super(
          handling: FormatHandling.image,
          processShare: 0.5,
        );

  @override
  TiffFormat copyWith({
    RenderScale? scale,
    Interpolation? interpolation,
  }) {
    return TiffFormat(
      scale: scale ?? this.scale,
      interpolation: interpolation ?? this.interpolation,
    );
  }

  @override
  String get extension => "tiff";
}
