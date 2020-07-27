import 'dart:async';

import 'package:flutter/services.dart';

class RecordMovie {
  static const MethodChannel _channel = const MethodChannel('record_movie');
  static const EventChannel _eventChannel = const EventChannel('record_movie/event');

  Stream<dynamic> _onBatteryStateChanged;

  Stream<dynamic> get onBatteryStateChanged {
    if (_onBatteryStateChanged == null) {
      _onBatteryStateChanged = _eventChannel.receiveBroadcastStream();
    }
    return _onBatteryStateChanged;
  }

  // 开始录制
  static Future<dynamic> startRecord({Map parame}) async {
    return await _channel.invokeMethod("startRecord", parame ?? {});
  }

  // 清除缓存
  static Future<dynamic> cleanCache() async {
    return await _channel.invokeMethod("cleanCache");
  }

  // 录制监听返回数据
  static recordListen({ bool type = true, Function onEvent, Function onError }) async {
    assert(onEvent != null);
    _eventChannel.receiveBroadcastStream( type ).listen(onEvent, onError: onError);
  }
}
