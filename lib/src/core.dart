import 'package:flutter/material.dart';
import 'package:render/render.dart';

class Render extends StatefulWidget {
  final RenderController controller;
  final Widget Function(BuildContext context, RenderSnapshot snapshot) builder;

  Render({
    Key? key,
    required this.builder,
    RenderController? controller,
  })  : controller = controller ?? RenderController(),
        super(key: key);

  @override
  State<Render> createState() => _RenderState();
}

class _RenderState extends State<Render> {
  final GlobalKey renderKey = GlobalKey();
  RenderSnapshot snapshot = RenderSnapshot();

  @override
  void initState() {
    super.initState();
    widget.controller.attach((snapshot) async {
      setState(() {
        this.snapshot = snapshot;
      });
      await WidgetsBinding.instance
          .waitUntilFirstFrameRasterized; // ? waitUntilFirstFrameRasterized
      return renderKey;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: renderKey,
      child: widget.builder(context, snapshot),
    );
  }
}
