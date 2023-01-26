import 'dart:async';

import 'package:render/src/formats/abstract.dart';
import 'package:render/src/service/notifier.dart';
import 'package:render/src/service/session.dart';
import 'package:render/src/service/settings.dart';
import 'package:render/src/service/task_identifier.dart';

import '../capturer.dart';
import '../process.dart';

class MotionRecorder<T extends MotionFormat> {
  /// All related render recording settings
  final MotionSettings capturingSettings;

  /// The output format of the recording
  final T format;

  /// What notifications should be displayed
  final LogLevel logLevel;
  late final StreamController<RenderNotifier> _notifier;
  late final RenderSession<T, MotionSettings> _session;
  late final RenderCapturer<T> _capturer;

  /// Starts a motion recording process
  MotionRecorder.start({
    required this.logLevel,
    required this.format,
    required this.capturingSettings,
    required TaskIdentifier task,
  }) {
    _notifier = StreamController<RenderNotifier>.broadcast();
    DetachedRenderSession.create(format, capturingSettings, logLevel)
        .then((detachedSession) {
      _session = RenderSession.fromDetached(
        detachedSession: detachedSession,
        notifier: _notifier,
        task: task,
      );
      _capturer = RenderCapturer(_session);
      _capturer.start();
    });
  }

  /// It is highly recommended to make use of stream for capturing motion,
  /// as the process usually takes longer and the user will likely wants to get
  /// notified the process of rendering for longer operations.
  Stream<RenderNotifier> get stream => _notifier.stream;

  /// Stops the recording and returns the result of the recording.
  Future<RenderResult> stop() async {
    final realSession = await _capturer.finish();
    final processor = MotionProcessor(realSession);
    processor.process(); // wait for result instead of process
    final result =
        await stream.singleWhere((element) => element.isResult) as RenderResult;
    _notifier.close();
    _session.dispose();
    return result;
  }
}
