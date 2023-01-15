
/*
class RenderLayer {
  ///Refers to whether the  layer should be build in the current context.
  final bool visible;
  final Widget child;
  late final GlobalKey globalKey = GlobalKey();
  final RenderProcessing processing;
  final RenderController controller;

  RenderLayer({
    this.visible = true,
    required this.controller,
    required this.child,
  }) : processing = RenderProcessing(controller.settings);

  Widget build() {
    //TODO: same as core render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.mainProcessing.isRunning) {
        processing.capture(globalKey);
        if (controller.currentFrame >= controller.settings.numberOfFrames) {
          processing.finish();
        }
      }
    });
    return RepaintBoundary(
      key: globalKey,
      child: child,
    );
  }
}


 */