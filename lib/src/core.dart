import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:render/src/service/task_identifier.dart';
import 'package:rich_console/printRich.dart';
import 'package:uuid/uuid.dart';

import 'dart:async';
import 'package:render/src/capturer.dart';
import 'package:render/src/formats/abstract.dart';
import 'package:render/src/formats/image.dart';
import 'package:render/src/formats/motion.dart';
import 'package:render/src/process.dart';
import 'package:render/src/service/motion_recorder.dart';
import 'package:render/src/service/session.dart';
import 'package:render/src/service/settings.dart';
import 'service/notifier.dart';

class RenderController {
  /// Holds task of rendering that are in the current widget tree.
  KeyIdentifier? _globalTask;

  /// The id of the render controller.
  /// A render controller can only have one [Render] widget assigned as a task.
  final UuidValue id;

  /// Log level of render methods. Note that the specific log level can also be
  /// override on each method itself. Console logs are only available in debug
  /// mode.
  final LogLevel logLevel;

  //TODO: render controller doc (copy from read me)
  RenderController({this.logLevel = LogLevel.debug})
      : id = UuidValue(const Uuid().v4());

  /// Creating a `RenderSession` from a `DetachedRenderSession`
  RenderSession<T, K> _createRenderSessionFrom<T extends RenderFormat,
          K extends RenderSettings>(
      DetachedRenderSession<T, K> detachedRenderSession,
      StreamController<RenderNotifier> notifier,
      [WidgetIdentifier? overwriteTask]) {
    assert(!kIsWeb, "Render does not support Web yet");
    assert(
        overwriteTask != null || _globalTask?.key.currentWidget != null,
        "RenderController must have a Render instance "
        "connected to create a session.");
    return RenderSession.fromDetached(
      detachedSession: detachedRenderSession,
      notifier: notifier,
      task: overwriteTask ?? _globalTask!,
    );
  }

  /// Listens to stream and prints out debug, if in debug mode.
  void _debugPrintOnStream(Stream<RenderNotifier> stream, String startMessage) {
    if (kDebugMode) {
      bool started = true;
      stream.listen((event) {
        if (started) {
          printRich("[Render plugin] $startMessage",
              foreground: Colors.lightGreen, bold: true, underline: true);
          started = false;
        }
        printRich(event.toString(),
            foreground: event.isError
                ? Colors.red
                : event.isResult
                    ? Colors.green
                    : event.isActivity
                        ? Colors.lightGreen
                        : event.isLog
                            ? Colors.blueGrey
                            : null);
      });
    }
  }

  /// Captures the [Render] widget and returns the result as future.
  ///
  /// Capturing an image is expected not to take too long in normal operations
  /// to make a stream necessary. For large image rendering or detail
  /// notifications of the process use [captureImageWithStream].
  ///
  /// Default file format is [ImageFormat.png]
  Future<RenderResult> captureImage({
    LogLevel? logLevel,
    ImageSettings settings = const ImageSettings(),
    ImageFormat format = const PngFormat(),
  }) async {
    final stream = captureImageWithStream(
      logLevel: logLevel ?? this.logLevel,
      settings: settings,
      format: format,
    );
    _debugPrintOnStream(stream, "Capturing image started");
    return await stream.firstWhere((element) => element.isResult)
        as RenderResult;
  }

  /// Captures an image and returns the result as future.
  ///
  /// Note that this method replaced the need for the [Render] widget as a parent
  /// widget. Simply pass the widget that need to be rendered in the function.
  ///
  /// Capturing an image is expected not to take too long in normal operations
  /// to make a stream necessary. For large image rendering or detail
  /// notifications of the process use [captureImageFromWidgetWithStream].
  ///
  /// Default file format is [ImageFormat.png]
  Future<RenderResult> captureImageFromWidget(
    Widget widget, {
    LogLevel? logLevel,
    ImageSettings settings = const ImageSettings(),
    ImageFormat format = const PngFormat(),
  }) async {
    final stream = captureImageFromWidgetWithStream(
      widget,
      logLevel: logLevel,
      settings: settings,
      format: format,
    );
    _debugPrintOnStream(stream, "Capturing image from widget started");
    return await stream.firstWhere((element) => element.isResult)
        as RenderResult;
  }

  /// Captures the motion of a widget and returns a future of the result.
  ///
  /// This function is only recommended for debug purposes.
  ///
  /// It is highly recommended to use [captureMotionWithStream] to capture
  /// motion, as the process usually takes longer and the user will likely wants
  /// to get notified with the stream about the process of rendering for longer
  /// operations.
  ///
  /// Default file format is [MotionFormat.mov]
  Future<RenderResult> captureMotion(
    Duration duration, {
    LogLevel? logLevel,
    MotionSettings settings = const MotionSettings(),
    MotionFormat format = const MovFormat(),
  }) async {
    final stream = captureMotionWithStream(
      duration,
      logLevel: logLevel,
      settings: settings,
      format: format,
    );
    _debugPrintOnStream(stream, "Capturing motion started");
    return await stream.firstWhere((element) => element.isResult)
        as RenderResult;
  }

  /// Captures motion of a widget that is out of the widget tree
  /// and returns a future with the result.
  ///
  /// Note that this method replaced the need for the [Render] widget as a parent
  /// widget. Simply pass the widget that need to be rendered in the function.
  ///
  /// This function is only recommended for debug purposes.
  ///
  /// It is highly recommended to use [captureMotionWithStream] to capture
  /// motion, as the process usually takes longer and the user will likely wants
  /// to get notified with the stream about the process of rendering for longer
  /// operations.
  ///
  /// Default file format is [MotionFormat.mov]
  Future<RenderResult> captureMotionFromWidget(
    Widget widget,
    Duration duration, {
    LogLevel? logLevel,
    MotionSettings settings = const MotionSettings(),
    MotionFormat format = const MovFormat(),
  }) async {
    final stream = captureMotionFromWidgetWithStream(
      widget,
      duration,
      logLevel: logLevel,
      settings: settings,
      format: format,
    );
    _debugPrintOnStream(stream, "Capturing motion from widget started");
    return await stream.firstWhere((element) => element.isResult)
        as RenderResult;
  }

  /// Captures an image and returns a stream of information of current
  /// operations and errors.
  ///
  /// Capturing an image is expected not to take too long in normal operations
  /// to make a stream necessary. For easy handling, it is recommended to simple
  /// use [captureImage].
  ///
  /// Default file format is [ImageFormat.png]
  Stream<RenderNotifier> captureImageWithStream({
    LogLevel? logLevel,
    ImageSettings settings = const ImageSettings(),
    ImageFormat format = const PngFormat(),
    bool logInConsole = false,
  }) {
    final notifier = StreamController<RenderNotifier>.broadcast();
    DetachedRenderSession.create(format, settings, logLevel ?? this.logLevel)
        .then((detachedSession) async {
      final session = _createRenderSessionFrom(detachedSession, notifier);
      final capturer = RenderCapturer(session);
      final realSession = await capturer.single();
      final processor = ImageProcessor(realSession);
      await processor.process();
    });
    if (logInConsole) {
      _debugPrintOnStream(notifier.stream, "Capturing image started");
    }
    return notifier.stream;
  }

  /// Captures motion of the [Render] widget and returns a stream of information
  /// of current operations and errors.
  ///
  /// It is highly recommended to use this method for capturing motion, as the
  /// process usually takes longer and the user will likely wants to get
  /// notified the process of rendering for longer operations.
  ///
  /// Default file format is [MotionFormat.mov]
  Stream<RenderNotifier> captureMotionWithStream(
    Duration duration, {
    LogLevel? logLevel,
    MotionSettings settings = const MotionSettings(),
    MotionFormat format = const MovFormat(),
    bool logInConsole = false,
  }) {
    final notifier = StreamController<RenderNotifier>.broadcast();
    DetachedRenderSession.create(format, settings, logLevel ?? this.logLevel)
        .then((detachedSession) async {
      final session = _createRenderSessionFrom(detachedSession, notifier);
      final capturer = RenderCapturer(session);
      final realSession = await capturer.run(duration);
      final processor = MotionProcessor(realSession);
      await processor.process();
    });
    if (logInConsole) {
      _debugPrintOnStream(notifier.stream, "Capturing motion started");
    }
    return notifier.stream;
  }

  /// Captures an image from a provided widget that is not in a widget tree
  /// and returns a stream of information of current operations and errors.
  ///
  /// Note that this method replaced the need for the [Render] widget as a parent
  /// widget. Simply pass the widget that need to be rendered in the function.
  ///
  /// Capturing an image is expected not to take too long in normal operations
  /// to make a stream necessary. For easy handling, it is recommended to simple
  /// use [captureImageFromWidget].
  ///
  /// Default file format is [ImageFormat.png]
  Stream<RenderNotifier> captureImageFromWidgetWithStream(
    Widget widget, {
    LogLevel? logLevel,
    ImageSettings settings = const ImageSettings(),
    ImageFormat format = const PngFormat(),
    bool logInConsole = false,
  }) {
    final widgetTask = WidgetIdentifier(controllerId: id, widget: widget);
    final notifier = StreamController<RenderNotifier>.broadcast();
    DetachedRenderSession.create(format, settings, logLevel ?? this.logLevel)
        .then((detachedSession) async {
      final session = _createRenderSessionFrom(
        detachedSession,
        notifier,
        widgetTask,
      );
      final capturer = RenderCapturer(session);
      final realSession = await capturer.single();
      final processor = ImageProcessor(realSession);
      await processor.process();
    });
    if (logInConsole) {
      _debugPrintOnStream(
          notifier.stream,
          "Capturing image from "
          "widget started");
    }
    return notifier.stream;
  }

  /// Captures motion of a widget that is out of the widget tree
  /// and returns a stream of information of current operations and errors.
  ///
  /// Note that this method replaced the need for the [Render] widget as a parent
  /// widget. Simply pass the widget that need to be rendered in the function.
  ///
  /// It is highly recommended to use this method for capturing motion, as the
  /// process usually takes longer and the user will likely wants to get
  /// notified the process of rendering for longer operations.
  ///
  /// For debugging it might be easier to use [captureMotion].
  ///
  /// Default file format is [MotionFormat.mov]
  Stream<RenderNotifier> captureMotionFromWidgetWithStream(
    Widget widget,
    Duration duration, {
    LogLevel? logLevel,
    MotionSettings settings = const MotionSettings(),
    MotionFormat format = const MovFormat(),
    bool logInConsole = false,
  }) {
    final widgetTask = WidgetIdentifier(controllerId: id, widget: widget);
    final notifier = StreamController<RenderNotifier>.broadcast();
    DetachedRenderSession.create(format, settings, logLevel ?? this.logLevel)
        .then((detachedSession) async {
      final session = _createRenderSessionFrom(
        detachedSession,
        notifier,
        widgetTask,
      );
      final capturer = RenderCapturer(session);
      final realSession = await capturer.run(duration);
      final processor = MotionProcessor(realSession);
      await processor.process();
    });
    if (logInConsole) {
      _debugPrintOnStream(
          notifier.stream,
          "Capturing motion from "
          "widget started");
    }
    return notifier.stream;
  }

  /// Records motion of the [Render] widget and returns a recording controller to
  /// `stop()` the recording or listen to a stream of information's and errors.
  ///
  /// Default file format is [MotionFormat.mov]
  MotionRecorder recordMotion({
    LogLevel? logLevel,
    MotionSettings settings = const MotionSettings(),
    MotionFormat format = const MovFormat(),
  }) {
    assert(!kIsWeb, "Render does not support Web yet");
    assert(
        _globalTask?.key.currentWidget != null,
        "RenderController must have a Render instance "
        "to start recording.");
    return MotionRecorder.start(
      format: format,
      capturingSettings: settings,
      task: _globalTask!,
      logLevel: logLevel ?? this.logLevel,
    );
  }

  /// Records motion of a widget and returns a recording controller to
  /// `stop()` the recording or listen to a stream of information's and errors.
  ///
  /// Default file format is [MotionFormat.mov]
  MotionRecorder recordMotionFromWidget(
    Widget widget, {
    LogLevel? logLevel,
    MotionSettings settings = const MotionSettings(),
    MotionFormat format = const MovFormat(),
  }) {
    assert(!kIsWeb, "Render does not support Web yet");
    return MotionRecorder.start(
      format: format,
      capturingSettings: settings,
      task: WidgetIdentifier(controllerId: id, widget: widget),
      logLevel: logLevel ?? this.logLevel,
    );
  }
}

class Render extends StatefulWidget {
  /// The render controller to initiate rendering
  final RenderController? controller;

  /// The child to be rendered. Note that
  /// [not all](https://github.com/polarby/render#%EF%B8%8F-known-issues)
  /// widgets can be rendered.
  final Widget child;

  /// A wrapper for rendering.
  /// Place the widget that needs to be rendered as a child and initiate a render
  /// by calling a method of [RenderController].
  ///
  ///
  /// ---
  ///```
  /// import 'package:render/render.dart';
  ///
  /// final controller = RenderController();
  ///
  /// Render(
  ///     controller: controller,
  ///     child: Container(),
  /// ),
  ///
  /// final result = await controller.captureMotion(Duration(seconds: 4));
  /// await controller.captureImage(format: ImageFormat.png, settings:  ImageSettings(pixelRatio: 3));
  /// ```
  ///
  /// ---
  ///
  const Render({
    Key? key,
    this.controller,
    required this.child,
  }) : super(key: key);

  @override
  State<Render> createState() => _RenderState();
}

class _RenderState extends State<Render> {
  final GlobalKey renderKey = GlobalKey();
  bool hasAttached = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      attach();
      hasAttached = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!hasAttached && widget.controller != null) {
      // *  try to attach for hot reload
      attach();
      hasAttached = true;
    }
    return RepaintBoundary(
      key: renderKey,
      child: widget.child,
    );
  }

  void attach() {
    assert(widget.controller != null);
    widget.controller!._globalTask = KeyIdentifier(
      controllerId: widget.controller!.id,
      key: renderKey,
    );
    hasAttached = true;
  }
}
