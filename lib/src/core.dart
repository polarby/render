import 'package:flutter/material.dart';
import 'package:render/src/controller.dart';

class Render extends StatelessWidget {
  final RenderController? controller;
  final Widget child;

  const Render({
    Key? key,
    this.controller,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //TODO: Check if widget in valid context -> render differently
    //TODO: register single render (so that there are not multiple instances)
    return RepaintBoundary(
      key: controller?.renderKey,
      child: child,
    );
  }
}
