import 'package:render/src/wrapper/service.dart';

import '../../render.dart';

class WrapperData {
  final WrapperType type;
  final RenderController controller;

  WrapperData({
    required this.controller,
    required this.type,
  });
}
