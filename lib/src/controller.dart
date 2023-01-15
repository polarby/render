import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:render/src/process.dart';
import 'package:render/src/snapshot.dart';
import 'package:render/src/settings.dart';

typedef Capturer = Future<GlobalKey> Function(RenderSnapshot snapshot);

class RenderController {
  Capturer? _capturer;

  void attach(Capturer capturer) {
    _capturer = capturer;
  }

  bool get isAttached => _capturer != null;

  Capturer get capturer {
    assert(isAttached, "RenderController is not attached.");
    return _capturer!;
  }

  Future<File> captureFrame([int frame = 0]) async {
    //TODO: render single frame
    throw UnimplementedError();
  }

  Future<File> capture(
      [RenderSettings settings = const RenderSettings.standard()]) async {
    final process = await RenderProcess.start(settings);
    print("start process with ${settings.numberOfFrames} number of frames");
    await Future.delayed(Duration(milliseconds: 100));
    for (int i = 0; i < settings.numberOfFrames; i++) {
      final buildKey = await capturer(
        RenderSnapshot(
          activity: RenderActivity.fromSettings(
            frame: i,
            settings: settings,
          ),
        ),
      );
      await process.capture(buildKey, i); // ? can await be removed
    }
    return await process.process();
  }
}
