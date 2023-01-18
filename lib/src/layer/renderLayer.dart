import 'package:flutter/cupertino.dart';

import '../../render.dart';

class RenderLayer extends StatelessWidget {
  final bool visibleInRender;
  final bool createNewVersion;
  final Widget child;
  late final GlobalKey globalKey = GlobalKey();
  final RenderController controller;

  RenderLayer({
    Key? key,
    this.createNewVersion = false,
    this.visibleInRender = true,
    required this.controller,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
