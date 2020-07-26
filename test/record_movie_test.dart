import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record_movie/record_movie.dart';

void main() {
  const MethodChannel channel = MethodChannel('record_movie');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await RecordMovie.startRecord(), '42');
  });
}
