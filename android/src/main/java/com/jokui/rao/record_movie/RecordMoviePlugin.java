package com.jokui.rao.record_movie;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.util.Log;

import androidx.annotation.NonNull;

import java.io.File;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import static com.jokui.rao.record_movie.PermissionsManager.checkVideoRecordPermission;


/** RecordMoviePlugin */
public class RecordMoviePlugin implements FlutterPlugin, ActivityAware, MethodCallHandler, EventChannel.StreamHandler  {
  /**
   * 录像需要的权限
   */
  public  static final String[] VIDEO_PERMISSIONS = {Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO,Manifest.permission.WRITE_EXTERNAL_STORAGE};

  private static Activity activity;
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private EventChannel eventChannel;

  private static final String METHOD_CHANNEL = "record_movie";
  private static final String EVENT_CHANNEL = "record_movie/event";

  public static EventChannel.EventSink _eventSink;
  public static Result resultData;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), METHOD_CHANNEL);
    eventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), EVENT_CHANNEL);

    eventChannel.setStreamHandler(this);
    channel.setMethodCallHandler(this);
  }

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "record_video");
    channel.setMethodCallHandler(new RecordMoviePlugin());
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull final Result result) {
    resultData = result;
    switch (call.method){
      case "startRecord":
        // 权限动态申请
        boolean permiss = checkVideoRecordPermission(activity);
        if( permiss ){
          Intent intent = new Intent(activity, RecordedActivity.class);
          boolean ishasCamera2 = Camera2Utils.hasCamera2(activity);

          if( ishasCamera2 ){
            intent = new Intent(activity, RecordedActivity2.class);
          }

          // 是否保存到相册
          intent.putExtra("isSaveGallery", !call.hasArgument("showFlash") || (boolean) call.argument("showFlash"));
          // 输出路径
          intent.putExtra("outFilePath", String.valueOf(call.hasArgument("outFilePath") ? call.argument("outFilePath"): ""));
          // 输出文件名
          intent.putExtra("outFileName", String.valueOf(call.hasArgument("outFileName") ? call.argument("outFileName"): ""));
          // 是否显示闪光灯按钮
          intent.putExtra("showFlash", !call.hasArgument("showFlash") || (boolean) call.argument("showFlash"));
          // 是否显示切换相机按钮
          intent.putExtra("showCamera", !call.hasArgument("showCamera") || (boolean) call.argument("showCamera"));
          // 最小时间
          intent.putExtra("minTime", call.hasArgument("minTime") ? (float)call.argument("minTime") : 1);
          // 最大时间
          intent.putExtra("maxTime", call.hasArgument("maxTime") ? (float)call.argument("maxTime") : 20);
          // 录制按钮的大小
          intent.putExtra("recordBtnSize", call.hasArgument("recordBtnSize") ? (int)call.argument("recordBtnSize") : 20);
          // 录制按钮的颜色
          intent.putExtra("recordBtnColor", String.valueOf(call.hasArgument("recordBtnColor") ? call.argument("recordBtnColor") : "#FFFFFF"));
          // 录制按钮上方的提示文字
          intent.putExtra("tipText", String.valueOf(call.hasArgument("tipText") ? call.argument("tipText") : "点击拍照, 长按录制"));
          // 录制按钮上方的提示文字(暂停时)
          intent.putExtra("tipPauseText", String.valueOf(call.hasArgument("tipPauseText") ? call.argument("tipPauseText") : "长按继续录制"));
          // 录制按钮上方的提示文字大小
          intent.putExtra("tipFontSize", call.hasArgument("tipFontSize") ? (int)call.argument("tipFontSize") : 20);
          // 录制按钮上方的提示文字颜色
          intent.putExtra("recordBtnColor", String.valueOf(call.hasArgument("recordBtnColor") ? call.argument("recordBtnColor") : "#FFFFFF"));
          // 是否开启回删功能
          intent.putExtra("isOpenDel", !call.hasArgument("isOpenDel") || (boolean) call.argument("isOpenDel"));
          // 录制时的进度条颜色
          intent.putExtra("progressColor", String.valueOf(call.hasArgument("progressColor") ? call.argument("progressColor") : "#00E2FC"));
          // 录制时的进度条宽度
          // intent.putExtra("progressWidth", Double.valueOf((Double) (call.hasArgument("progressWidth") ? call.argument("progressWidth") : 6)));
          // 录制时的进度条背景颜色
          intent.putExtra("progressBgColor", String.valueOf(call.hasArgument("progressBgColor") ? call.argument("progressBgColor") : "#aadddddd"));
          // 录制暂停时的断点颜色
          intent.putExtra("splitColor", String.valueOf(call.hasArgument("splitColor") ? call.argument("splitColor") : "#FFFFFF"));
          // 录制暂停时的断点的大小
          intent.putExtra("splitWidth", call.hasArgument("splitWidth") ? (float) call.argument("splitWidth") : 20.0);
          // 录制后删除断点进度的颜色
          activity.startActivity(intent);
        }
        break;
      case "cleanCache":
        cleanCache(String.valueOf(call.hasArgument("cleanDir") ? call.argument("cleanDir") : ""), result);
      default:
        result.notImplemented();
        break;
    }
  }


  ///activity 生命周期
  @Override
  public void onAttachedToActivity(ActivityPluginBinding activityPluginBinding) {
    Log.e("onAttachedToActivity", "onAttachedToActivity" + activityPluginBinding);
    activity = activityPluginBinding.getActivity();
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {

  }

  @Override
  public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {

  }

  @Override
  public void onDetachedFromActivity() {

  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    eventChannel.setStreamHandler(null);
  }

  @Override
  public void onListen(Object arguments, EventChannel.EventSink events) {
    Log.d("TAG", "onListen: "+events);
    if( _eventSink == null){
      _eventSink = events;
    }
  }

  @Override
  public void onCancel(Object arguments) {
    if( _eventSink != null){
      _eventSink = null;
    }
  }

  //删除文件夹和文件夹里面的文件
  private void cleanCache(String pPath, Result result) {
    pPath = pPath.isEmpty() ? activity.getExternalCacheDir().getPath() + "/video/" : pPath;
    File dirFile = new File(pPath);
    if (!dirFile.exists()) {
      deleteDirWihtFile(dirFile);
    }
    result.success(true);
  }

  private void deleteDirWihtFile(File dir) {
    if (dir == null || !dir.exists() || !dir.isDirectory())
      return;
    for (File file : dir.listFiles()) {
      if (file.isFile())
        file.delete(); // 删除所有文件
      else if (file.isDirectory())
        deleteDirWihtFile(file); // 递规的方式删除文件夹
    }
    dir.delete();// 删除目录本身
  }
}
