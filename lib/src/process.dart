import 'package:ffmpeg_kit_flutter_https_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/log.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/statistics.dart';
import 'package:flutter/material.dart';
import 'package:render/render.dart';
import 'package:render/src/service/session.dart';
import 'package:rich_console/printRich.dart';
import 'service/exception.dart';

abstract class RenderProcessor<T extends RenderFormat> {
  final RenderSession<T, EndCapturingSettings> session;

  ///Duration of capturing if applicable (not on images)

  RenderProcessor({
    required this.session,
  });

  bool _processing = false;

  String get inputPath;

  ///Converts saved frames from temporary directory to output file
  Future<void> process() async {
    if (_processing) {
      throw const RenderException(
          "Cannot start new process, during an active one.");
    }
    // * Preparation
    _processing = true;
    final outputFile =
        session.createOutputFile("output_main.${session.format.extension}");
    // * Receive operation processing instructions
    final operation = session.format.processor(
      inputPath: inputPath,
      outputPath: outputFile.path,
      frameRate: session.settings.realFrameRate,
    );
    // * Execute processing instructions
    try {
      printRich("execute ffmpeg: ${operation.arguments}",
          foreground: Colors.orange);
      await _executeCommand(
        operation.arguments,
        progressShare: session.format.processShare,
      );
      //TODO: add layers
      session.recordResult(outputFile);
      _processing = false;
    } on RenderException catch (error) {
      session.recordError(error);
    }
  }

  /// Wrapper around the FFmpeg command execution. Takes care of notifying the
  /// session about the progress of execution.
  Future<void> _executeCommand(List<String> command,
      {bool isLayer = false, required double progressShare}) async {
    final ffmpegSession = await FFmpegSession.create(
      command,
      (ffmpegSession) async {
        session.recordActivity(
          isLayer ? RenderState.layerProcessing : RenderState.mainProcessing,
          progressShare,
          message: "Completed ffmpeg operation",
          details: "[async notification] Ffmpeg session completed: "
              "${ffmpegSession.getSessionId()}, time needed: "
              "${await ffmpegSession.getDuration()}, execution: "
              "${ffmpegSession.getCommand()}, logs: "
              "${await ffmpegSession.getLogsAsString()}, return code: "
              "${await ffmpegSession.getReturnCode()}, stack trace: "
              "${await ffmpegSession.getFailStackTrace()}",
        );
      },
      (Log log) {
        print("level: ${log.getLevel()}, logs: ${log.getMessage()}");
        //session.recordLog(log.getMessage());
      },
      (Statistics statistics) {
        final progression = ((statistics.getTime() * 100) ~/
                    session.settings.capturingDuration.inMilliseconds)
                .clamp(0, 100) /
            100;
        session.recordActivity(
          isLayer ? RenderState.layerProcessing : RenderState.mainProcessing,
          progression.toDouble(),
          message: "Processing captures",
        );
      },
    );
    await FFmpegKitConfig.ffmpegExecute(ffmpegSession).timeout(
      session.settings.processTimeout,
      onTimeout: () {
        printError("ffmpeg session timeout");
        ffmpegSession.cancel();
      },
    );
  }

//TODO: complex filter (layers)
}

class ImageProcessor extends RenderProcessor<ImageFormat> {
  ImageProcessor({
    required super.session,
  });

  @override
  String get inputPath => "${session.inputDirectory}/frame0.png";
}

class MotionProcessor extends RenderProcessor<MotionFormat> {
  MotionProcessor({
    required super.session,
  });

  @override
  String get inputPath => "${session.inputDirectory}/frame%d.png";
}
