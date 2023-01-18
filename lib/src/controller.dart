import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:render/src/capturer.dart';
import 'package:render/src/process.dart';
import 'package:render/src/session.dart';
import 'package:render/src/settings.dart';

import 'notifier.dart';

class RenderController {
  final GlobalKey renderKey;
  final SchedulerBinding _binding;

  RenderController({
    SchedulerBinding? binding,
  })  : renderKey = GlobalKey(),
        _binding = binding ?? SchedulerBinding.instance;

  //TODO: do command without stream (parameter option for terminal notifications)

  /// Creating a `RenderSession` from a `DetachedRenderSession`
  RenderSession<T> _renderSessionFrom<T extends RenderSettings>(
      DetachedRenderSession<T> detachedRenderSession,
      StreamController<RenderNotifier> notifier) {
    return RenderSession<T>.fromDetached(
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
  StreamController<RenderNotifier> captureImageWithStream(
      [ImageSettings settings = const ImageSettings()]) {
    final notifier = StreamController<RenderNotifier>.broadcast();
    DetachedRenderSession.create(settings).then((detachedSession) async {
      final session = _renderSessionFrom(detachedSession, notifier);
      final capturer = RenderCapturer(settings: settings, session: session);
      await capturer.single();
      //TODO: ImageRenderProcess: process layers & conversion
      notifier.add(
        RenderResult(
          output: File("${session.inputDirectory}/frame0.png"),
          usedSettings: settings,
          timestamp: session.currentTimeStamp,
        ),
      );
    });
    return notifier;
  }

  StreamController<RenderNotifier> captureMotionWithStream(Duration duration,
      [MotionSettings settings = const MotionSettings()]) {
    final notifier = StreamController<RenderNotifier>.broadcast();
    DetachedRenderSession.create(settings)
        .then((detachedSession) async {
      final session = _renderSessionFrom(detachedSession, notifier);
      final capturer = RenderCapturer(settings: settings, session: session);
      await capturer.run(duration, settings.frameRate);
      final processor = MotionRenderProcess(session: session);
      await processor.process();
    });
    return notifier;
  }

  Future<dynamic> recordMotionWithStream(
      [MotionSettings motionSettings = const MotionSettings()]) async {
    //TODO: implement
    throw UnimplementedError();
  }
}
