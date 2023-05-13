import 'dart:io';

import 'package:ffmpeg_kit_flutter_https_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/log.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/statistics.dart';
import 'package:render/src/formats/abstract.dart';
import 'package:render/src/service/notifier.dart';
import 'package:render/src/service/session.dart';
import 'package:render/src/service/settings.dart';
import 'service/exception.dart';

abstract class RenderProcessor<T extends RenderFormat> {
  final RenderSession<T, RenderSettings> session;

  RenderProcessor(this.session, this.width, this.height);

  bool _processing = false;

  String get inputPath;

  int width;

  int height;

  ///Converts saved frames from temporary directory to output file
  Future<void> process() async {
    if (_processing) {
      throw const RenderException(
          "Cannot start new process, during an active one.");
    }
    _processing = true;
    try {
      final output = await _processTask(session.format.processShare);
      session.recordResult(output);
      _processing = false;
    } on RenderException catch (error) {
      session.recordError(error);
    }
  }

  /// Processes task frames and writes the output with the specific format
  /// Returns the process output file.
  Future<File> _processTask(double progressShare) async {
    final mainOutputFile =
        session.createOutputFile("output_main.${session.format.extension}");
    double frameRate = 1;
    if (session.settings.isMotion) {
      frameRate = session.settings.asMotion!.frameRate.toDouble();
    }
    // Receive main operation processing instructions
    final operation = session.format.processor(
        inputPath: inputPath,
        outputPath: mainOutputFile.path,
        frameRate: frameRate,
        width: width,
        height: height);
    await _executeCommand(
      operation.arguments,
      progressShare: progressShare,
    );
    return mainOutputFile;
  }

  /// Wrapper around the FFmpeg command execution. Takes care of notifying the
  /// session about the progress of execution.
  Future<void> _executeCommand(List<String> command,
      {required double progressShare}) async {
    final ffmpegSession = await FFmpegSession.create(
      command,
      (ffmpegSession) async {
        session.recordActivity(
          RenderState.processing,
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
        final message = log.getMessage();
        if (message.toLowerCase().contains("error")) {
          session.recordError(RenderException(
            "[Ffmpeg execution error] $message",
            fatal: true,
          ));
        } else {
          session.recordLog(message);
        }
      },
      (Statistics statistics) {
        session.recordActivity(
          RenderState.processing,
          null,
          message: "Converting captures",
        );
      },
    );
    await FFmpegKitConfig.ffmpegExecute(ffmpegSession).timeout(
      session.settings.processTimeout,
      onTimeout: () {
        session.recordError(
          const RenderException(
            "Processing session timeout",
            fatal: true,
          ),
        );
        ffmpegSession.cancel();
      },
    );
  }
}

class ImageProcessor extends RenderProcessor<ImageFormat> {
  ImageProcessor(super.session, super.width, super.height);

  @override
  String get inputPath => session.inputPipe;
}

class MotionProcessor extends RenderProcessor<MotionFormat> {
  MotionProcessor(super.session, super.width, super.height);

  @override
  String get inputPath => session.inputPipe;
}
