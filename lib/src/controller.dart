import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:render/src/capturer.dart';
import 'package:render/src/formats/abstract.dart';
import 'package:render/src/formats/image.dart';
import 'package:render/src/formats/motion.dart';
import 'package:render/src/process.dart';
import 'package:render/src/service/session.dart';
import 'package:render/src/service/settings.dart';
import 'service/notifier.dart';

class RenderController {
  final GlobalKey renderKey;
  final SchedulerBinding _binding;

  RenderController({
    SchedulerBinding? binding,
  })  : renderKey = GlobalKey(),
        _binding = binding ?? SchedulerBinding.instance;

  //TODO: do command without stream (parameter option for terminal notifications)

  /// Creating a `RenderSession` from a `DetachedRenderSession`
  RenderSession<T, K> _createRenderSessionFrom<T extends RenderFormat,
          K extends CapturingSettings>(
      DetachedRenderSession<T, K> detachedRenderSession,
      StreamController<RenderNotifier> notifier) {
    return RenderSession.fromDetached(
      detachedSession: detachedRenderSession,
      binding: _binding,
      notifier: notifier,
      renderKey: renderKey,
    );
  }

  /// Captures an image and returns a stream of information of current
  /// operations and errors.
  /// Capturing an image is expected not to take too long in normal operations
  /// to make a stream necessary. For easy handling, it is recommended to simple
  /// use [captureImage].
  ///
  /// Default file format is [ImageFormat.png]
  Stream<RenderNotifier> captureImageWithStream({
    CapturingSettings capturingSettings = const CapturingSettings(),
    ImageFormat format = const PngFormat(),
  }) {
    final notifier = StreamController<RenderNotifier>.broadcast();
    DetachedRenderSession.create(format, capturingSettings)
        .then((detachedSession) async {
      final session = _createRenderSessionFrom(detachedSession, notifier);
      final capturer =
          RenderCapturer(settings: capturingSettings, session: session);
      final realSession = await capturer.single();
      final processor = ImageProcessor(session: realSession);
      await processor.process();
    });
    return notifier.stream;
  }

  ///Default is [MotionFormat.mov]
  Stream<RenderNotifier> captureMotionWithStream(
    Duration duration, {
    CapturingSettings capturingSettings = const CapturingSettings(),
    MotionFormat format = const MovFormat(),
  }) {
    final notifier = StreamController<RenderNotifier>.broadcast();
    DetachedRenderSession.create(format, capturingSettings)
        .then((detachedSession) async {
      final session = _createRenderSessionFrom(detachedSession, notifier);
      final capturer =
          RenderCapturer(settings: capturingSettings, session: session);
      final realSession = await capturer.run(duration);
      final processor = MotionProcessor(session: realSession);
      await processor.process();
    });
    return notifier.stream;
  }

  ///Default is [MotionFormat.mov]
  Future<dynamic> recordMotionWithStream({
    CapturingSettings capturingSettings = const CapturingSettings(),
    MotionFormat format = const MovFormat(),
  }) async {
    //TODO: implement
    throw UnimplementedError();
  }
}
