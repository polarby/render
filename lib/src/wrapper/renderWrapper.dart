import 'dart:io';

import 'package:flutter/material.dart';
import 'package:render/render.dart';
import 'package:render/src/wrapper/service.dart';
import 'package:render/src/wrapper/wrapperData.dart';

/// A wrapper for widgets that are considered platform views (Example: Google
/// Maps, Camera, Vide players, etc.). Wrappers will build the platform-view
/// widget in a normal state, but will return a frame by frame flutter widget of
/// the platform-view when rendering, so it can later be processed by
/// the [Render] widget.
class RenderWrapper extends StatefulWidget {
  final WrapperData data;

  RenderWrapper.videoPlayer({
    super.key,
    required RenderController controller,
    required File video,
  }) : data = WrapperData(
          type: WrapperType.videoPlayer,
          controller: controller,
        );

  RenderWrapper.custom({
    super.key,
    required RenderController controller,
  }) : data = WrapperData(controller: controller, type: WrapperType.custom);

  @override
  State<RenderWrapper> createState() => _RenderWrapperState();
}

class _RenderWrapperState extends State<RenderWrapper> {
  @override
  void initState() {
// TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.data.type) {
      case WrapperType.videoPlayer:
        return const Placeholder();
      case WrapperType.custom:
        return const Placeholder();
    }
  }
}
