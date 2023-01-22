import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../render.dart';
import '../formats/abstract.dart';
import 'exception.dart';
import 'notifier.dart';

/// A detached render session is a render session that is not attached to a view
class DetachedRenderSession<T extends RenderFormat,
    K extends CapturingSettings> {
  /// Pointer to session files and operation.
  final String sessionId;

  /// Directory of a temporary storage, where files can be used for processing.
  /// This should be somewhere in a RAM location for fast processing.
  final String temporaryDirectory;

  /// Where internal files are being written (frames, layers, palettes, etc.)
  /// Note that there will be additional sub-directories that separate different
  /// internal actions and sessions. Directories will be deleted after a session.
  final String inputDirectory;

  /// Where result files are being written
  final String outputDirectory;

  /// A directory where files are being written that are used for processing.
  final String processDirectory;

  /// All render related settings
  final K settings;

  final T format;

  /// A class that holds information about the current detached session. Ranging
  /// from directories to session identification.
  DetachedRenderSession({
    required this.outputDirectory,
    required this.inputDirectory,
    required this.sessionId,
    required this.temporaryDirectory,
    required this.processDirectory,
    required this.settings,
    required this.format,
  });

  /// Creates a detached render session from default values (paths & session syntax)
  /// Attach a session by initializing RenderPaint and Context values by
  /// extending with [RenderSession]
  static Future<DetachedRenderSession<T, K>>
      create<T extends RenderFormat, K extends CapturingSettings>(
          T format, K settings) async {
    final tempDir = await getTemporaryDirectory();
    final sessionId = const Uuid().v4();
    return DetachedRenderSession<T, K>(
      outputDirectory: "${tempDir.path}/render/$sessionId/output",
      inputDirectory: "${tempDir.path}/render/$sessionId/input",
      processDirectory: "${tempDir.path}/render/$sessionId/process",
      sessionId: sessionId,
      temporaryDirectory: tempDir.path,
      settings: settings,
      format: format,
    );
  }

  ///Creates a new file path if not present and returns the file as directory
  File _createFile(String path) {
    final outputFile = File(path);
    if (!outputFile.existsSync()) outputFile.createSync(recursive: true);
    return outputFile;
  }

  /// Creating a file in the input directory.
  File createInputFile(String subPath) =>
      _createFile("$inputDirectory/$subPath");

  /// Creating a file in the output directory.
  File createOutputFile(String subPath) =>
      _createFile("$outputDirectory/$subPath");

  /// Creating a file in the process directory.
  File createProcessFile(String subPath) =>
      _createFile("$processDirectory/$subPath");
}

class RenderSession<T extends RenderFormat, K extends CapturingSettings>
    extends DetachedRenderSession<T, K> {
  /// Key to the RepaintBoundary of the [Render] widget.
  final GlobalKey renderKey;

  /// Binding to the Context of the [Render] widget.
  final SchedulerBinding binding;

  /// Session notifier to all activity in this session.
  final StreamController<RenderNotifier> _notifier;

  /// Start time of session. Is the reference for timestamps and
  /// remaining time calculation.
  final DateTime startTime;

  /// A class that holds all the information about the current session.
  /// used to pass information between the different parts of the rendering
  /// process.
  RenderSession({
    required super.settings,
    required super.inputDirectory,
    required super.outputDirectory,
    required super.processDirectory,
    required super.sessionId,
    required super.temporaryDirectory,
    required super.format,
    required this.binding,
    required this.renderKey,
    required StreamController<RenderNotifier> notifier,
    DateTime? startTime,
  })  : _notifier = notifier,
        startTime = startTime ?? DateTime.now();

  RenderState? _currentState;

  /// A constructor that takes a `DetachedRenderSession` and creates a
  /// `RenderSession` from it.
  RenderSession.fromDetached({
    required DetachedRenderSession<T, K> detachedSession,
    required StreamController<RenderNotifier> notifier,
    required this.binding,
    required this.renderKey,
    DateTime? startTime,
  })  : _notifier = notifier,
        startTime = DateTime.now(),
        super(
          format: detachedSession.format,
          settings: detachedSession.settings,
          processDirectory: detachedSession.processDirectory,
          inputDirectory: detachedSession.inputDirectory,
          outputDirectory: detachedSession.outputDirectory,
          sessionId: detachedSession.sessionId,
          temporaryDirectory: detachedSession.temporaryDirectory,
        );

  /// Upgrade the current renderSession to a real session
  RenderSession<T, EndCapturingSettings> upgrade(
      Duration capturingDuration, int frameAmount) {
    return RenderSession<T, EndCapturingSettings>(
      settings: EndCapturingSettings(
        pixelRatio: settings.pixelRatio,
        processTimeout: settings.processTimeout,
        capturingDuration: capturingDuration,
        frameAmount: frameAmount,
      ),
      startTime: startTime,
      inputDirectory: inputDirectory,
      outputDirectory: outputDirectory,
      processDirectory: processDirectory,
      sessionId: sessionId,
      temporaryDirectory: temporaryDirectory,
      format: format,
      binding: binding,
      renderKey: renderKey,
      notifier: _notifier,
    );
  }

  /// Returns the duration from the start of the session until now.
  Duration get currentTimeStamp {
    return Duration(
      milliseconds: DateTime.now().millisecondsSinceEpoch -
          startTime.millisecondsSinceEpoch,
    );
  }

  /// A method that is used to record activity in the session.
  void recordActivity(RenderState state, double? stateProgression,
      {String? message, String? details}) {
    if (_currentState != state) _currentState = state;
    _notifier.add(
      RenderActivity(
        timestamp: currentTimeStamp,
        state: state,
        currentStateProgression: stateProgression ?? 0.5,
        message: message,
        details: details,
      ),
    );
  }

  /// A method that is used to record errors in the session.
  void recordError(RenderException exception, {bool fatal = true}) {
    _notifier.add(
      RenderError(
        timestamp: currentTimeStamp,
        fatal: fatal,
        exception: exception,
      ),
    );
  }

  //TODO: optional layer id
  /// Recording the result of the render session.
  void recordResult(File output, {String? message, String? details}) {
    _notifier.add(
      RenderResult(
        format: format,
        timestamp: currentTimeStamp,
        usedSettings: settings as EndCapturingSettings,
        output: output,
        message: message,
        details: details,
      ),
    );
    dispose();
  }

  /// Disposing the current render session.
  Future<void> dispose() async {
    if (Directory(inputDirectory).existsSync()) {
      Directory(inputDirectory).deleteSync(recursive: true);
    }
    if (Directory(processDirectory).existsSync()) {
      Directory(processDirectory).deleteSync(recursive: true);
    }
    await _notifier.close();
  }
}
