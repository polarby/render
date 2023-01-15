import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:render/src/settings.dart';
import 'package:uuid/uuid.dart';

class RenderProcess {
  final RenderSettings settings;
  final String sessionId;
  final Directory temporaryDirectory;

  RenderProcess({
    String? sessionId,
    required this.settings,
    required this.temporaryDirectory,
  }) : sessionId = sessionId ?? const Uuid().v4();

  static Future<RenderProcess> start(RenderSettings settings) async {
    return RenderProcess(
      settings: settings,
      temporaryDirectory: await getTemporaryDirectory(),
    );
  }

  String get inputDirectory =>
      "${temporaryDirectory.path}/render/$sessionId/input";

  String get outputDirectory =>
      "${temporaryDirectory.path}/render/$sessionId/output";

  ///Converts saved frames from temporary directory to output file
  Future<File> process() async {
    final outputPath = "$outputDirectory/output_$sessionId.mp4";
    final outputFile = File(outputPath);
    if (!outputFile.existsSync()) await outputFile.create(recursive: true);
    final process = await FFmpegKit.execute(
        "-y " // replace output file if it already exists
        "-framerate ${settings.frameRate} "
        "-i $inputDirectory/frame%d.png " // input frames
        "$outputPath" // output format
        );
    final logs = await process.getLogs();
    print("FFmpegKit-logs: ${logs.map((e) => e.getMessage())}");
    return outputFile;
  }

  Future<void> capture(GlobalKey contentKey, int frameNumber) async {
    try {
      assert(contentKey.currentContext != null,
          "The current widget context is not valid");
      //capture context
      final RenderRepaintBoundary boundary = contentKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(
          pixelRatio: 3.0); // ? should be edited in settings
      //convert to file
      final ByteData? byteData = await image.toByteData(
          format: ui.ImageByteFormat.png); // ? can be jpg for transparent video
      final rawIntList = byteData!.buffer.asInt8List().toList();
      final File file = File('$inputDirectory/frame$frameNumber.png');
      if (!file.existsSync()) await file.create(recursive: true);
      await file.writeAsBytes(rawIntList);
      image.dispose();
      print("done capturing frame: $frameNumber");
    } catch (e) {
      rethrow;
    }
  }
}
