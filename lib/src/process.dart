import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:render/src/session.dart';
import 'package:render/src/settings.dart';
import 'exception.dart';

class RenderProcessor<T extends RenderSettings> {
  final RenderSession<T> session;

  RenderProcessor({
    required this.session,
  });

  bool processing = false;

}

class ImageRenderProcess extends RenderProcessor<ImageSettings> {
  ImageRenderProcess({
    required super.session,
  });
}

class MotionRenderProcess extends RenderProcessor<MotionSettings> {

  MotionRenderProcess({
    required super.session,
  });

  ///Converts saved frames from temporary directory to output file
  Future<void> process() async {
    if (processing) {
      throw const RenderException(
          "Cannot start new process, during an active one.");
    }
    processing = true;
    final outputFile =
    await session.createOutputFile(
        "output_main.${session.settings.format.name}");
    final paletteFile = await session.createProcessFile("palette.png");
    final palette = await FFmpegKit.executeWithArguments([
      "-y",
      "-i",
      "${session.inputDirectory}/frame%d.png",
      "-vf",
      "palettegen",
      paletteFile.path
    ]);
    final process = await FFmpegKit.executeWithArguments([
      "-y",
      "-v",
      "warning",
      "-i",
      "${session.inputDirectory}/frame%d.png",
      "-i",
      paletteFile.path,
      "-lavfi",
      "paletteuse,setpts=3*PTS",
      outputFile.path
    ]);
    /*
    final process = await FFmpegKit.executeWithArguments([
      "-y",
      "-framerate",
      settings.frameRate.toString(),
      "-i",
      "$inputDirectory/frame%d.png",
      "-gifflags",
      "-offsetting",
      outputPath
    ]);
     */
    final logs = await process.getLogs();
    print("FFmpegKit-logs: ${logs.map((e) => e.getMessage())}");
    processing = false;

    session.recordResult(outputFile);
  }
}
