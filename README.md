# record_movie

这是一个原生的flutter视频录制插件

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


