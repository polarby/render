import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:flutter/rendering.dart';
import 'package:render/src/notifier.dart';
import 'package:render/src/session.dart';
import 'package:render/src/settings.dart';
import 'exception.dart';

class RenderCapturer {
  /// Settings of how each frame should be rendered.
  final RenderSettings settings;

  /// Current session captures should be assigned to.
  final RenderSession session;

  RenderCapturer({
    required this.settings,
    required this.session,
  });

  /// Current image handling process. Handlers are being handles asynchronous
  /// as conversion and file writing is involved.
  final List<Future<void>> _handlers = [];

  bool _rendering = false;

  /// Runs a capturing process for a defined time.
  Future<void> run(Duration duration, int targetFrameRate) async {
    start(targetFrameRate, duration);

    await Future.delayed(duration);

    await finish();
  }

  /// Takes a single capture
  Future<void> single() async {
    final image = _captureContext();
    await _handleCapture(image, 0);
  }

  /// Starts new capturing process for unknown duration
  void start(int targetFrameRate, [Duration? duration]) {
    assert(!_rendering, "Cannot start new process, during an active one.");
    _rendering = true;
    session.binding.addPostFrameCallback((duration) =>
        _postFrameCallback(duration, 0, targetFrameRate, duration));
  }

  /// Finishes current capturing process
  Future<void> finish() async {
    assert(_rendering, "Cannot finish capturing as, no active capturing.");
    _rendering = false;
    await Future.wait(_handlers); //await all active capture handlers
    _handlers.clear();
  }

  /// A callback function that is called after each frame is rendered.
  void _postFrameCallback(Duration timestamp, int frame, int targetFrameRate,
      [Duration? duration]) async {
    if (!_rendering) return;
    final nextMilliSecond = (1 / targetFrameRate) * frame * 1000;
    if (nextMilliSecond > timestamp.inMilliseconds) {
      // add a new PostFrameCallback to know about the next frame
      session.binding.addPostFrameCallback((duration) =>
          _postFrameCallback(duration, frame, targetFrameRate, duration));
      // but we do nothing, because we skip this frame
      return;
    }
    try {
      final totalFrameTarget =
          duration != null ? duration.inSeconds * targetFrameRate : null;
      final image = _captureContext();
      _handlers.add(_handleCapture(image, frame, totalFrameTarget));
      _recordActivity(RenderState.capturing, frame, totalFrameTarget,
          "Captured frame $frame.");
    } on RenderException catch (exception) {
      session.recordError(
        exception,
        fatal: false,
      );
    }
    session.binding.addPostFrameCallback((duration) =>
        _postFrameCallback(duration, frame + 1, targetFrameRate, duration));
  }

  /// Converting the raw image data to a png file and writing the capture.
  Future<void> _handleCapture(ui.Image capture, int captureNumber,
      [int? totalFrameTarget]) async {
    try {
      // * retrieve bytes
      final ByteData? byteData =
          await capture.toByteData(format: ui.ImageByteFormat.rawRgba);
      final rawIntList = byteData!.buffer.asInt8List();
      // * write raw file for processing
      final rawFile = await session
          .createInputFile("frameHandling/frame_raw$captureNumber.bmp");
      await rawFile.writeAsBytes(rawIntList);
      // * write & convert file (to save storage)
      final file = await session.createInputFile("frame$captureNumber.png");
      await FFmpegKit.executeWithArguments([
        "-y",
        "-f",
        "rawvideo",
        "-pixel_format",
        "rgba",
        "-video_size",
        "${capture.width}x${capture.height}",
        "-i",
        rawFile.path,
        file.path,
      ]);
      // * finish
      capture.dispose();
      rawFile.deleteSync();
      if (!_rendering) {
        //only record next state, when rendering is done not to mix up notification
        _recordActivity(RenderState.handleCaptures, captureNumber,
            totalFrameTarget, "Handled frame $captureNumber.");
      }
    } catch (e) {
      session.recordError(
        RenderException(
          "Handling frame context unsuccessful. Trying next frame.",
          details: e,
        ),
        fatal: false,
      );
    }
  }

  /// Using the `RenderRepaintBoundary` to capture the current frame.
  ui.Image _captureContext() {
    try {
      final renderObject = session.renderKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (renderObject == null) {
        throw const RenderException(
          "Capturing frame context unsuccessful as context is null."
          " Trying next frame.",
        );
      }
      return renderObject.toImageSync(pixelRatio: settings.pixelRatio);
    } catch (e) {
      throw RenderException(
        "Unknown error while capturing frame context. Trying next frame.",
        details: e,
      );
    }
  }

  /// Recording the activity of the current session specifically for capturing
  void _recordActivity(
      RenderState state, int frame, int? totalFrameTarget, String message) {
    if (totalFrameTarget != null) {
      session.recordActivity(state, (1 / totalFrameTarget) * frame, message);
    } else {
      // capturing activity when recording (no time limit set)
      session.recordActivity(state, null, message);
    }
  }
}
