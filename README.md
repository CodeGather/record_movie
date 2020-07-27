# record_movie

这是一个原生的flutter视频录制插件，实现录制视频后返回视频路径，由于项目需求用来代替ffmpeg视频处理的方案。

## 支持程度

|    平台  | 支持  |
| :------:|:----:|
| Android  | YES |
| Ios      | YES |

### 相关功能

- 支持断点续录
- 支持回删功能
- 支持切换相机（前后）
- 支持开启闪光灯

为减小安卓包大小，所以安卓和iOS都未采用ffmpeg来处理视频

安卓端使用cmaera、camera2、MediaRecorder、mp4parser 等等
iOS端使用AVCaptureConnection、AVMutableComposition 等等

### 遇到以及可能存在的问题

1、安卓端存在录制的实际视频内用与倒计时的进度有偏差，目前解决的方案是每次录制完成后重新获取他的视频时间长度，然后下次录制的时间是总时间减去已录制的时间，这就造成了倒计时的进度天有可能做的快时间断点偏前的尴尬局面，如果仔细观察你会发现进度条会在断点的后方重新跑。

2、安卓端遇到camera和camera2的兼容问题，目前的解决办法是单独分开，一边后期维护，即两个布局文件、两个activity、两个Utils

3、安卓端遇到传递JSONObject数据时出现解析错误的情况，解决方案是用第三方库com.alibaba:fastjson 来替换本身自带的json解析

4、iOS端遇到打开iOS原生端controller的问题

5、iOS端状态栏问题，理论上打开视频录制界面时应该隐藏状态栏（还未实现）

6、iOS端返回数据使用FlutterEventSink来处理返回数据

7、iOS端事件代理、事件回调、线程执行、如何使用主线程等等问题

8、iOS端使用result时代理方法只执行一次的问题，解决方案是去除全局的xDVideocamera，改成每次点击的时候都进行初始化

<img src="https://raw.githubusercontent.com/CodeGather/record_movie/master/screenshot/android.gif" alt="android截图1" width="100">
<img src="https://raw.githubusercontent.com/CodeGather/record_movie/master/screenshot/ios.gif" alt="android截图2" width="100">
