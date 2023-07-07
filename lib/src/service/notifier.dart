import 'dart:io';
import 'package:render/src/service/session.dart';
import 'package:render/src/service/settings.dart';
import '../formats/abstract.dart';
import 'exception.dart';

abstract class RenderNotifier {
  ///The current progression of the rendering time
  final Duration timestamp;

  RenderNotifier({
    required this.timestamp,
  });

  @override
  String toString();

  bool get isResult => this is RenderResult;

  bool get isError => this is RenderError;

  bool get isActivity => this is RenderActivity;

  bool get isLog => this is RenderLog;

  bool get isFatalError => isError && (this as RenderError).fatal;
}

/// Used to notify the user about an error that has occurred in the
/// rendering process.
class RenderError extends RenderNotifier {
  /// An exception, that has essential influence in render process.
  final RenderException exception;

  /// Used to determine if the error is fatal or not.
  final bool fatal;

  RenderError({
    required this.fatal,
    required this.exception,
    required super.timestamp,
  });

  @override
  String toString() {
    return "RenderError(timestamp: $timestamp, exception: $exception, fatal: $fatal)";
  }
}

class RenderLog extends RenderNotifier {
  /// Message of the current activity change. This message usually is an internal
  /// message and is not suitable for front-end display.
  final String message;

  /// Used to notify the user about the current log of the rendering process.
  RenderLog({
    required this.message,
    required super.timestamp,
  });

  @override
  String toString() {
    return "RenderLog(timestamp: $timestamp, message: ${message.replaceAll(RegExp(r"\s+"), " ")})";
  }
}

class RenderActivity extends RenderNotifier {
  ///Message of the current activity change. This message may be displayed
  ///in the front end to notifier user about the current state of rendering.
  final String? message;

  /// Insight details to the current operation. This may be used for in depth
  /// feedback and debugging
  final String? details;

  ///The current operation of rendering
  final RenderState state;

  /// Progressing in Percentage. Used to calculate the expected time remaining.
  final double currentStateProgression;

  final RenderSession _session;

  /// Used to notify the user about the current state of the rendering process.
  RenderActivity({
    required this.state,
    required this.currentStateProgression,
    this.message,
    this.details,
    required RenderSession session,
    required super.timestamp,
  })  : _session = session,
        assert(
          currentStateProgression >= 0.0 && currentStateProgression <= 1.0,
        );

  /// The calculated expected amount of time needed until rendering is finished.
  /// This value is based on the execution time of previous operations and does
  /// not necessarily represent the actual remaining time.
  /// If null, it currently has not enough data to predict
  /// the time duration.
  Duration? get timeRemaining {
    final expectedTime = totalExpectedTime;
    if (expectedTime == null) return null;
    return Duration(
      milliseconds: expectedTime.inMilliseconds - timestamp.inMilliseconds,
    );
  }

  /// The current expected progression of rendering.
  /// This value is based on the execution time of previous operations and does
  /// not necessarily represent the actual remaining time.
  double get progressPercentage {
    final percentagePassed = RenderState.values
        .sublist(0, RenderState.values.indexOf(state))
        .fold(
            0.0,
            (previousValue, element) =>
                previousValue + _session.processingShare(element));
    return currentStateProgression * _session.processingShare(state) +
        percentagePassed;
  }

  /// Calculating the total time that is expected to be needed to render the
  /// widget.
  /// If null, it currently has not enough data to predict
  /// the time duration.
  Duration? get totalExpectedTime {
    final progress = progressPercentage;
    if (progress == 0.0) return null;
    return Duration(milliseconds: timestamp.inMilliseconds ~/ progress);
  }

  @override
  String toString() {
    return "RenderActivity(timestamp: $timestamp, state: ${state.name} message:"
        " $message, ${details != null ? "details: $details, " : ""}"
        "timeRemaining: ${timeRemaining?.inMinutes}:"
        "${timeRemaining?.inSeconds},"
        " progressPercentage: "
        "${(progressPercentage * 100).toStringAsPrecision(3)}%,"
        " totalExpectedTime: ${totalExpectedTime?.inMinutes}:"
        "${totalExpectedTime?.inSeconds})";
  }
}

class RenderResult extends RenderActivity {
  /// The output file. Note that the file is stored in a temporary directory, all
  /// data might be deleted any time. To store permanently make sure to write it
  /// to a permanent directory (see getApplicationDocumentsDirectory()
  /// via [path_provider](https://pub.dev/packages/path_provider) plugin)
  final File output;

  ///The settings used to create the output file.
  final RenderSettings usedSettings;

  final RenderFormat format;

  RenderResult({
    required this.format,
    required this.output,
    required this.usedSettings,
    super.message,
    super.details,
    required super.timestamp,
    required RenderSession session,
  }) : super(
          state: RenderState.finishing,
          currentStateProgression: 1,
          session: session,
        );

  ///The time that was needed to render the widget (=timestamp)
  Duration get totalRenderTime => timestamp;

  @override
  String toString() {
    return "RenderResult(timestamp: $timestamp, "
        "${message != null ? "message: $message, " : ""}"
        "totalRenderTime: $totalRenderTime)";
  }
}

/// A state machine that is used to track the current state of the
/// rendering process.
/// ! This enum is order sensitive
enum RenderState {
  /// Process of taking the RepaintBoundary of the widget frame by frame.
  /// Note that the handling of captures already starts in this process
  /// (see [handleCaptures])
  capturing,

  /// Converting captures and writing in a processable file format to a
  /// temporary directory. This process start already in [capturing] and
  /// finishes after capturing, as this process is asynchronous
  /// (see [RenderCapturer]> handlers)
  handleCaptures,

  /// Main processing of frames to convert to the dedicated file format.
  /// This is separated in [ImageRenderProcess] and [MotionRenderProcess].
  processing,

  /// Disposing of session and returning result. This state usually is not
  /// asynchronous and just represents the end state.
  finishing;
}

/// Which logs should be displayed in the console or notification stream
/// during rendering. [RenderResult] will always be displayed.
enum LogLevel {
  /// No logging
  none,

  /// Main activity, which includes all [RenderActivity]
  activity,

  /// Debug logging, all [RenderActivity] and [RenderLog] notifications
  debug
}
