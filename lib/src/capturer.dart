import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:flutter/rendering.dart';
import 'package:render/render.dart';
import 'package:render/src/service/notifier.dart';
import 'package:render/src/service/session.dart';
import 'package:render/src/service/settings.dart';
import 'service/exception.dart';

class RenderCapturer<K extends RenderFormat> {
  /// Settings of how each frame should be rendered.
  final CapturingSettings settings;

  /// Current session captures should be assigned to.
  final RenderSession<K, CapturingSettings> session;

  RenderCapturer({
    required this.settings,
    required this.session,
  });

  /// Current image handling process. Handlers are being handles asynchronous
  /// as conversion and file writing is involved.
  final List<Future<void>> _handlers = [];

  /// A flag to indicate whether the capturing process is running or not.
  bool _rendering = false;

  ///The time position of capture start of the duration of the scheduler binding.
  Duration? startingDuration;

  DateTime? startTime;

  /// Runs a capturing process for a defined time. Returns capturing time duration.
  Future<RenderSession<K, EndCapturingSettings>> run(Duration duration) async {
    start(duration);

    await Future.delayed(duration);

    return await finish();
  }

  /// Takes a single capture
  Future<RenderSession<K, EndCapturingSettings>> single() async {
    startTime = DateTime.now();
    final image = _captureContext();
    _recordActivity(RenderState.capturing, 1,1, "Captured image.");
    await _handleCapture(image, 0);
    _recordActivity(RenderState.handleCaptures, 1,1, "Handled image.");
    final capturingDuration = Duration(
        milliseconds: DateTime.now().millisecondsSinceEpoch -
            startTime!.millisecondsSinceEpoch);
    return session.upgrade(capturingDuration, 1);
  }

  /// Starts new capturing process for unknown duration
  void start([Duration? duration]) {
    assert(!_rendering, "Cannot start new process, during an active one.");
    _rendering = true;
    startTime = DateTime.now();
    session.binding.addPostFrameCallback((binderTimeStamp) {
      startingDuration = session.binding.currentFrameTimeStamp;
      _postFrameCallback(
        binderTimeStamp: binderTimeStamp,
        frame: 0,
        duration: duration,
      );
    });
  }

  /// Finishes current capturing process. Returns the total capturing time.
  Future<RenderSession<K, EndCapturingSettings>> finish() async {
    assert(_rendering, "Cannot finish capturing as, no active capturing.");
    _rendering = false;
    startingDuration = null;
    final capturingDuration = Duration(
        milliseconds: DateTime.now().millisecondsSinceEpoch -
            startTime!.millisecondsSinceEpoch);
    final frameAmount = _handlers.length;
    await Future.wait(_handlers); //await all active capture handlers
    _handlers.clear();
    return session.upgrade(capturingDuration, frameAmount);
  }

  /// A callback function that is called after each frame is rendered.
  void _postFrameCallback({
    required Duration binderTimeStamp,
    required int frame,
    Duration? duration,
  }) async {
    if (!_rendering) return;
    final targetFrameRate = session.settings.frameRate;
    final relativeTimeStamp =
        binderTimeStamp - (startingDuration ?? Duration.zero);
    final nextMilliSecond = (1 / targetFrameRate) * frame * 1000;
    if (nextMilliSecond > relativeTimeStamp.inMilliseconds) {
      // add a new PostFrameCallback to know about the next frame
      session.binding.addPostFrameCallback(
        (binderTimeStamp) => _postFrameCallback(
          binderTimeStamp: binderTimeStamp,
          frame: frame,
          duration: duration,
        ),
      );
      // but we do nothing, because we skip this frame
      return;
    }
    try {
      final totalFrameTarget =
          duration != null ? duration.inSeconds * targetFrameRate : null;
      final image = _captureContext();
      _handlers.add(_handleCapture(image, frame, totalFrameTarget));
      _recordActivity(RenderState.capturing, frame, totalFrameTarget,
          "Captured frame $frame");
    } on RenderException catch (exception) {
      session.recordError(
        exception,
        fatal: false,
      );
    }
    session.binding.addPostFrameCallback(
      (binderTimeStamp) => _postFrameCallback(
        binderTimeStamp: binderTimeStamp,
        frame: frame + 1,
        duration: duration,
      ),
    );
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
      final rawFile =
          session.createInputFile("frameHandling/frame_raw$captureNumber.bmp");
      await rawFile.writeAsBytes(rawIntList);
      // * write & convert file (to save storage)
      final file = session.createInputFile("frame$captureNumber.png");
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
            totalFrameTarget, "Handled frame $captureNumber");
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
      session.recordActivity(state, (1 / totalFrameTarget) * frame,
          message: message);
    } else {
      // capturing activity when recording (no time limit set)
      session.recordActivity(state, null, message: message);
    }
  }
}
