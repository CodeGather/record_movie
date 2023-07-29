import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:record_movie/record_movie.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _resultMsg = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
//    RecordMovie.recordListen(onEvent: success);
  }

  void success(event){
    setState(() {
      _resultMsg = event['data'];
    });
    print('333-3-3-3-3-3-3--3$event');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('返回数据: $_resultMsg\n'),
              ElevatedButton(
                onPressed: () async{
                  final data = await RecordMovie.startRecord(parame: {
                    "isSaveGallery": false
//                    "tipText": "测试提示文字哦",
//                    "isOpenDel": false,
//                    "progressWidth": 36
                  });
                  print("------------$data");
                },
                child: Text('开始录制'),
              ),
              ElevatedButton(
                onPressed: () async{
                  await RecordMovie.cleanCache();
                },
                child: Text('清除缓存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
