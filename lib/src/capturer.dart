import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter_https_gpl/ffmpeg_kit_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:render/src/service/notifier.dart';
import 'package:render/src/service/session.dart';
import 'package:render/src/service/settings.dart';
import 'package:render/src/service/task_identifier.dart';
import 'formats/abstract.dart';
import 'service/exception.dart';

class RenderCapturer<K extends RenderFormat> {
  /// Settings of how each frame should be rendered.

  /// Current session captures should be assigned to.
  final RenderSession<K, RenderSettings> session;

  /// Context of the flutter app, if a widget should be captured
  final BuildContext? context;

  RenderCapturer(this.session, [this.context]);

  /// Current image handling process. Handlers are being handles asynchronous
  /// as conversion and file writing is involved.
  final List<Future<void>> _handlers = [];

  /// A flag to indicate whether the capturing process is running or not.
  bool _rendering = false;

  ///The time position of capture start of the duration of the scheduler binding.
  Duration? startingDuration;

  /// Start tim of capturing
  DateTime? startTime;

  /// The size of the first frame. Used to maintain equality of size throughout
  /// capturing.
  /// In duration the actual "first" frame will be disposed and the next frame
  /// will be seen as first frame.
  Size? firstFrameSize;

  /// The writer to write the captured images to.
  IOSink? _frameWriter;

  /// Runs a capturing process for a defined time. Returns capturing time duration.
  Future<RenderSession<K, RealRenderSettings>> run(Duration duration) async {
    start(duration);

    await Future.delayed(duration);

    return await finish();
  }

  /// Takes a single capture
  Future<RenderSession<K, RealRenderSettings>> single() async {
    startTime = DateTime.now();
    _captureFrame(0, 1);
    await Future.wait(_handlers);
    final capturingDuration = Duration(
        milliseconds: DateTime.now().millisecondsSinceEpoch -
            startTime!.millisecondsSinceEpoch);
    return session.upgrade(capturingDuration, 1);
  }

  /// Starts new capturing process for unknown duration
  void start([Duration? duration]) async {
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
  Future<RenderSession<K, RealRenderSettings>> finish() async {
    assert(_rendering, "Cannot finish capturing as, no active capturing.");
    final capturingDuration = Duration(
        milliseconds: DateTime.now().millisecondsSinceEpoch -
            startTime!.millisecondsSinceEpoch); // log end of capturing
    _rendering = false;
    startingDuration = null;
    // * wait for handlers
    await Future.wait(_handlers);
    // * finish capturing, notify session
    final frameAmount = _handlers.length;
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
    final targetFrameRate = session.settings.asMotion?.frameRate ?? 1;
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
      _captureFrame(frame, totalFrameTarget);
    } on RenderException catch (exception) {
      session.recordError(exception);
      if (exception.fatal) return;
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
  Future<void> _handleCapture(
    ui.Image capture,
    int captureNumber, [
    int? totalFrameTarget,
  ]) async {
    try {
      // * retrieve bytes
      // toByteData(format: ui.ImageByteFormat.png) takes way longer than raw
      // and then converting to png with ffmpeg
      final ByteData? byteData =
          await capture.toByteData(format: ui.ImageByteFormat.rawRgba);
      final rawIntList = byteData!.buffer.asInt8List();

      // * write image to pipe
      _writeToPipe(rawIntList);

      // * finish
      capture.dispose();
      if (!_rendering) {
        //only record next state, when rendering is done not to mix up notification
        _recordActivity(RenderState.handleCaptures, captureNumber,
            totalFrameTarget, "Handled frame $captureNumber");
      }
    } catch (e) {
      session.recordError(
        RenderException(
          "Handling frame $captureNumber unsuccessful.",
          details: e,
        ),
      );
    }
  }

  /// Captures associated task of this frame
  void _captureFrame(int frameNumber, [int? totalFrameTarget]) {
    // * capture
    ui.Image image;
    if (session.task is KeyIdentifier) {
      image = _captureContext((session.task as KeyIdentifier).key);
    } else if (session.task is WidgetIdentifier) {
      image = _captureWidget((session.task as WidgetIdentifier).widget);
    } else {
      throw const RenderException("Could not identify render task.");
    }
    // * Check for valid frame size
    // [Resolved] https://github.com/polarby/render/issues/9
    final frameSize = Size(image.width.toDouble(), image.height.toDouble());
    firstFrameSize ??= frameSize;
    if (frameSize != firstFrameSize) {
      throw const RenderException(
        "Invalid frame sizes. "
        "All Render frames must have a fixed size during capturing",
        details:
            "The render widget might be wrapped by an expandable widget that "
            "changes size during capturing.",
        fatal: true,
      );
    }
    // * initiate handler
    _handlers.add(_handleCapture(image, frameNumber, totalFrameTarget));
    _recordActivity(RenderState.capturing, frameNumber, totalFrameTarget,
        "Captured frame $frameNumber");
  }

  /// Using the `RenderRepaintBoundary` to capture the current frame.
  ui.Image _captureContext(GlobalKey key) {
    try {
      final renderObject =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (renderObject == null) {
        throw const RenderException(
          "Capturing frame context unsuccessful as context is null."
          " Trying next frame.",
        );
      }
      return renderObject.toImageSync(pixelRatio: session.settings.pixelRatio);
    } catch (e) {
      throw RenderException(
        "Unknown error while capturing frame context. Trying next frame.",
        details: e,
      );
    }
  }

  /// Captures a widget-frame that is not build in a widget tree.
  /// Inspired by [screenshot plugin](https://github.com/SachinGanesh/screenshot)
  ui.Image _captureWidget(Widget widget) {
    assert(context != null,
        "Capturing from widget requires valid context of in RenderCapturer.");
    try {
      final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();

      final flutterView = View.of(context!);
      Size logicalSize =
          flutterView.physicalSize / flutterView.devicePixelRatio;
      Size imageSize = flutterView.physicalSize;

      assert(logicalSize.aspectRatio.toStringAsPrecision(5) ==
          imageSize.aspectRatio.toStringAsPrecision(5));

      final RenderView renderView = RenderView(
        view: flutterView,
        child: RenderPositionedBox(
            alignment: Alignment.center, child: repaintBoundary),
        configuration: ViewConfiguration(
          size: logicalSize,
          devicePixelRatio: session.settings.pixelRatio,
        ),
      );

      final PipelineOwner pipelineOwner = PipelineOwner();
      final BuildOwner buildOwner =
          BuildOwner(focusManager: FocusManager(), onBuildScheduled: () {});

      pipelineOwner.rootNode = renderView;
      renderView.prepareInitialFrame();

      final RenderObjectToWidgetElement<RenderBox> rootElement =
          RenderObjectToWidgetAdapter<RenderBox>(
              container: repaintBoundary,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: widget,
              )).attachToRenderTree(
        buildOwner,
      );
      buildOwner.buildScope(
        rootElement,
      );
      buildOwner.finalizeTree();

      pipelineOwner.flushLayout();
      pipelineOwner.flushCompositingBits();
      pipelineOwner.flushPaint();
      /*
      try {
        /// Dispose All widgets
        rootElement.visitChildren((Element element) {
          rootElement.deactivateChild(element);
        });
        buildOwner.finalizeTree();
      } catch (_) {}
       */

      return repaintBoundary.toImageSync(
          pixelRatio: session.settings.pixelRatio);
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
      session.recordActivity(
          state, ((1 / totalFrameTarget) * frame).clamp(0.0, 1.0),
          message: message);
    } else {
      // capturing activity when recording (no time limit set)
      session.recordActivity(state, null, message: message);
    }
  }

  /// Opens the pipe to the ffmpeg process
  void openPipe() {
    var f = File(session.inputPipe);
    _frameWriter = f.openWrite();
  }

  /// Closes the pipe to the ffmpeg process
  Future<void> closePipe() async {
    await _frameWriter?.close();
    await FFmpegKitConfig.closeFFmpegPipe(session.inputPipe);
  }

  /// Writes data to the pipe to the ffmpeg process
  void _writeToPipe(List<int> data) {
    return _frameWriter?.add(data);
  }
}
