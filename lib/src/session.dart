import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../render.dart';
import 'exception.dart';
import 'notifier.dart';

/// A detached render session is a render session that is not attached to a view
class DetachedRenderSession<T extends RenderSettings> {
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

  final T settings;

  /// A class that holds information about the current detached session. Ranging
  /// from directories to session identification.
  DetachedRenderSession({
    required this.outputDirectory,
    required this.inputDirectory,
    required this.sessionId,
    required this.temporaryDirectory,
    required this.processDirectory,
    required this.settings,
  });

  /// Creates a detached render session from default values (paths & session syntax)
  /// Attach a session by initializing RenderPaint and Context values by
  /// extending with [RenderSession]
  static Future<DetachedRenderSession<T>> create<T extends RenderSettings>(
      T settings) async {
    final tempDir = await getTemporaryDirectory();
    final sessionId = const Uuid().v4();
    return DetachedRenderSession<T>(
      outputDirectory: "${tempDir.path}/render/$sessionId/output",
      inputDirectory: "${tempDir.path}/render/$sessionId/input",
      processDirectory: "${tempDir.path}/render/$sessionId/process",
      sessionId: sessionId,
      temporaryDirectory: tempDir.path,
      settings: settings,
    );
  }

  ///Creates a new file path if not present and returns the file as directory
  Future<File> _createFile(String path) async {
    final outputFile = File(path);
    if (!outputFile.existsSync()) await outputFile.create(recursive: true);
    return outputFile;
  }

  /// Creating a file in the input directory.
  Future<File> createInputFile(String subPath) =>
      _createFile("$inputDirectory/$subPath");

  /// Creating a file in the output directory.
  Future<File> createOutputFile(String subPath) =>
      _createFile("$outputDirectory/$subPath");

  /// Creating a file in the process directory.
  Future<File> createProcessFile(String subPath) =>
      _createFile("$processDirectory/$subPath");
}

class RenderSession<T extends RenderSettings> extends DetachedRenderSession<T> {
  /// Key to the RepaintBoundary of the [Render] widget.
  final GlobalKey renderKey;

  /// Binding to the Context of the [Render] widget.
  final SchedulerBinding binding;

  /// Session notifier to all activity in this session.
  final StreamController<RenderNotifier> notifier;

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
    required this.binding,
    required this.notifier,
    required this.renderKey,
    DateTime? startTime,
  }) : startTime = DateTime.now();

  RenderState? _currentState;

  /// A constructor that takes a `DetachedRenderSession` and creates a
  /// `RenderSession` from it.
  RenderSession.fromDetached({
    required DetachedRenderSession<T> detachedSession,
    required this.binding,
    required this.notifier,
    required this.renderKey,
    DateTime? startTime,
  })  : startTime = DateTime.now(),
        super(
          settings: detachedSession.settings,
          processDirectory: detachedSession.processDirectory,
          inputDirectory: detachedSession.inputDirectory,
          outputDirectory: detachedSession.outputDirectory,
          sessionId: detachedSession.sessionId,
          temporaryDirectory: detachedSession.temporaryDirectory,
        );

  /// Returns the duration from the start of the session until now.
  Duration get currentTimeStamp => Duration(
        milliseconds: DateTime.now().millisecond - startTime.millisecond,
      );

  /// A method that is used to record activity in the session.
  void recordActivity(RenderState state, double? stateProgression,
      [String? message]) {
    if (_currentState != state) _currentState = state;
    notifier.add(
      RenderActivity(
        timestamp: currentTimeStamp,
        state: state,
        currentStateProgression: stateProgression ?? 0.5,
        message: message,
      ),
    );
  }

  /// A method that is used to record errors in the session.
  void recordError(RenderException exception, {bool fatal = true}) {
    notifier.add(
      RenderError(
        timestamp: currentTimeStamp,
        fatal: fatal,
        exception: exception,
      ),
    );
  }

  //TODO: optional layer id
  void recordResult(File output) {
    notifier.add(
      RenderResult(
        timestamp: currentTimeStamp,
        output: output,
        usedSettings: settings,
      ),
    );
  }
}
