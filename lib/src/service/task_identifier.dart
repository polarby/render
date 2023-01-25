import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

abstract class TaskIdentifier {
  /// The id of the controller the task is assigned to.
  final UuidValue controllerId;

  /// An identifier for a render task. This can either be an id of a widget
  /// in a tree or a widget itself (out of context rendering).
  TaskIdentifier({
    required this.controllerId,
  });
}

class WidgetIdentifier extends TaskIdentifier {
  final Widget widget;

  /// An Identifier for a widget out of context
  WidgetIdentifier({
    required super.controllerId,
    required this.widget,
  });
}

class KeyIdentifier extends TaskIdentifier {
  final GlobalKey key;

  /// An identifier for a widget within a context and rendering
  KeyIdentifier({
    required super.controllerId,
    required this.key,
  });
}
