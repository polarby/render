import 'package:render/src/settings.dart';

class RenderSnapshot {
  final RenderState renderState;
  final RenderActivity? activity;

  RenderSnapshot({
    this.activity,
  }) : renderState = activity?.activeState ?? RenderState.none;

  @override
  String toString() {
    return "RenderSnapshot(renderState: ${renderState.name}, activity: $activity)";
  }
}

enum RenderState {
  rendering,
  done,
  none;

  bool get isActive => this == RenderState.rendering;

  bool get isFinished => this == RenderState.done;
}
