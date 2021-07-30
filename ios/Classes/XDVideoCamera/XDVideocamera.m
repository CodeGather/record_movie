//
//  XDVideocamera.m
//  摄像
//
//  Created by 谢兴达 on 2017/3/1.
//  Copyright © 2017年 谢兴达. All rights reserved.
//

#import "XDVideocamera.h"
#import "VideoUI.h"
#import "UIImage+Resize.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "XDVideoManager.h"
#import "StoreFileManager.h"
#import "VideoRecordProgressView.h"

static const BOOL bool_true = true;
static const BOOL bool_false = false;

typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

@interface XDVideocamera ()<VideoUIDelegate,AVCaptureFileOutputRecordingDelegate>
@property (strong,nonatomic) AVCaptureSession *session;                     //会话管理
@property (strong,nonatomic) AVCaptureDeviceInput *deviceInput;             //负责从AVCaptureDevice获得输入数据
@property (strong,nonatomic) AVCaptureMovieFileOutput *movieFileOutput;     //视频输出流
@property (strong,nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer; //相机拍摄预览图层
@property (strong,nonatomic) AVCaptureStillImageOutput *imageOutPut;        //图片输出流
@property (nonatomic,assign) UIDeviceOrientation orientation;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) CGFloat recordTime;                              //录制时间
@property (nonatomic, strong) NSMutableArray *videoArray;
@property (nonatomic, strong) NSMutableDictionary *dict;           //返回数据

@property (strong,nonatomic) CALayer *previewLayer; //视频预览layer层
@property (strong,nonatomic) UIView *focusView;     //聚焦
@property (assign,nonatomic) BOOL enableRotation;   //是否允许旋转（注意在视频录制过程中禁止屏幕旋转）
@property (assign,nonatomic) BOOL isTurnON;         //是否开启闪关灯
@property (assign,nonatomic) CGRect *lastBounds;    //旋转的前大小
@property (assign,nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;//后台任务标识

@end

@implementation XDVideocamera

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.session startRunning];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.session stopRunning];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _videoArray = [[NSMutableArray alloc]init];
    _dict = [[NSMutableDictionary alloc]init];
    [self creatMainUI];
}

// 创建录制UI
- (void)creatMainUI {
  VideoUI *uiView = [[VideoUI alloc]initWithFrame:self.view.frame];
  [uiView viewsLinkBlock:^(UIView *focusView, SelectView *previewView) {
      self.previewLayer = previewView.layer;
      self.previewLayer.masksToBounds = YES;
      self.focusView = focusView;
  }];

  // 设置最大时间
  uiView.KMaxRecordTime = self.KMaxRecordTime;
  
  [uiView setFormData:_dict];
  
  uiView.delegate = self;
  
  uiView.cancelBlock = self.cancelBlock;
  
  uiView.completionBlock = self.completionBlock;
  
  self.view = uiView;
  
  [self configSessionManager];
}

-(BOOL)shouldAutorotate{
    return self.enableRotation;
}

//屏幕旋转时调整预览图层
//- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
//    AVCaptureConnection *connection = [self.videoPreviewLayer connection];
//    connection.videoOrientation = (AVCaptureVideoOrientation)toInterfaceOrientation;
//}
//
//旋转后重新设置大小
//- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
//    _videoPreviewLayer.frame = self.previewLayer.bounds;
//}

// 隐藏状态栏
-  (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark -- 会话管理初始化
- (void)configSessionManager {
    //初始化会话
    _session = [[AVCaptureSession alloc]init];
    [self changeConfigurationWithSession:_session block:^(AVCaptureSession *session) {
        if ([session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
            [session setSessionPreset:AVCaptureSessionPresetHigh];
        }
        
        //获取输入设备
        AVCaptureDevice *device = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];
        if (!device) {
            NSLog(@"获取后置摄像头失败");
            return;
        }
        
        //添加一个音频输入设备
        AVCaptureDevice *audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio]firstObject];
        if (!audioDevice) {
            NSLog(@"获取麦克风失败");
        }
        
        //用当前设备初始化输入数据
        NSError *error = nil;
        self.deviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:device error:&error];
    
        if (error) {
            NSLog(@"获取视频输入对象失败 原因:%@",error.localizedDescription);
            return;
        }
        
        //用当前音频设备初始化音频输入
        AVCaptureDeviceInput *audioInput = [[AVCaptureDeviceInput alloc]initWithDevice:audioDevice error:&error];
        if (error) {
            NSLog(@"获取音频输入对象失败 原因:%@",error.localizedDescription);
        }
        
        //初始化设备输出对象
        self.movieFileOutput = [[AVCaptureMovieFileOutput alloc]init];
        
        //将设备的输入输出添加到会话管理
        if ([session canAddInput:self.deviceInput]) {
            [session addInput:self.deviceInput];
            [session addInput:audioInput];
        }
        
        if ([session canAddOutput:self.movieFileOutput]) {
            [session addOutput:self.movieFileOutput];
        }
      
        if ([session canAddOutput:self.imageOutPut]) {
            [session addOutput:self.imageOutPut];
        }
        
        //创建视频预览层，用于实时展示摄像头状态
        self.videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:session];
        
        self.videoPreviewLayer.frame = self.previewLayer.bounds;
        self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        
        [self.previewLayer insertSublayer:self.videoPreviewLayer below:self.focusView.layer];
        
        self.enableRotation = YES;
        [self addNotificationToDevice:device];
    }];
}

#pragma mark - 通知
/**
 给输入设备添加通知
 */
-(void)addNotificationToDevice:(AVCaptureDevice *)captureDevice{
    //注意添加区域改变捕获通知必须首先设置设备允许捕获
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        captureDevice.subjectAreaChangeMonitoringEnabled=YES;
    }];
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    //捕获区域发生改变
    [notificationCenter addObserver:self selector:@selector(areaChanged:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
    //链接成功
    [notificationCenter addObserver:self selector:@selector(deviceConnected:) name:AVCaptureDeviceWasConnectedNotification object:captureDevice];
    //链接断开
    [notificationCenter addObserver:self selector:@selector(deviceDisconnected:) name:AVCaptureDeviceWasDisconnectedNotification object:captureDevice];
}


-(void)removeNotificationFromDevice:(AVCaptureDevice *)captureDevice{
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
    [notificationCenter removeObserver:self name:AVCaptureDeviceWasConnectedNotification object:captureDevice];
    [notificationCenter removeObserver:self name:AVCaptureDeviceWasDisconnectedNotification object:captureDevice];
}

/**
 移除所有通知
 */
-(void)removeNotification{
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self];
}

-(void)addNotificationToCaptureSession:(AVCaptureSession *)captureSession{
    NSNotificationCenter *notificationCenter= [NSNotificationCenter defaultCenter];
    //会话出错
    [notificationCenter addObserver:self selector:@selector(sessionError:) name:AVCaptureSessionRuntimeErrorNotification object:captureSession];
}

/**
 设备连接成功
 
 @param notification 通知对象
 */
-(void)deviceConnected:(NSNotification *)notification{
    NSLog(@"设备已连接...");
}

/**
 设备连接断开
 
 @param notification 通知对象
 */
-(void)deviceDisconnected:(NSNotification *)notification{
    NSLog(@"设备已断开.");
}

/**
 捕获区域改变
 
 @param notification 通知对象
 */
-(void)areaChanged:(NSNotification *)notification{
    NSLog(@"区域改变...");
    CGPoint cameraPoint = [self.videoPreviewLayer captureDevicePointOfInterestForPoint:self.view.center];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
}

/**
 会话出错
 
 @param notification 通知对象
 */
-(void)sessionError:(NSNotification *)notification{
    NSLog(@"会话错误.");
}

#pragma mark -- 工具方法
/**
 取得指定位置的摄像头
 
 @param position 摄像头位置

 @return 摄像头设备
 */
-(AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position]==position) {
            return camera;
        }
    }
    return nil;
}

/**
 改变设备属性的统一操作方法
 
 @param propertyChange 属性改变操作
 */
-(void)changeDeviceProperty:(PropertyChangeBlock)propertyChange{
    AVCaptureDevice *captureDevice= [self.deviceInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        if (propertyChange) {
           propertyChange(captureDevice);
        }
        [captureDevice unlockForConfiguration];
        
    }else{
        NSLog(@"出错了，错误信息：%@",error.localizedDescription);
    }
}

/**
 改变会话同意操作方法

 @param currentSession self.session
 @param block Session操作区域
 */
- (void)changeConfigurationWithSession:(AVCaptureSession *)currentSession block:(void (^)(AVCaptureSession *session))block {
    [currentSession beginConfiguration];
    if (block) {
        block(currentSession);
    }
    [currentSession commitConfiguration];
}

/**
 获取时间

 @return 返回日期，用日期命名
 */
- (NSString *)getCurrentDate {
    //用日期做为视频文件名称
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *dateStr = [formatter stringFromDate:[NSDate date]];
    return dateStr;
}

/**
 提示框

 @param title 提示内容
 @param btn 取消按钮
 @return 提示框
 */
- (UIAlertView *)noticeAlertTitle:(NSString *)title cancel:(NSString *)btn {
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:title message:nil delegate:self cancelButtonTitle:btn otherButtonTitles:nil, nil];
    [alert show];
    return alert;
}

#pragma mark -- 清除视频Url路径下的缓存
/**
 @param urlArray _videoArray
 */
- (void)freeArrayAndItemsInUrlArray:(NSArray *)urlArray {
    if (urlArray.count <= 0) {
        return;
    }
    for (NSURL *url in urlArray) {
        [[StoreFileManager defaultManager] removeItemAtUrl:url];
    }
}

#pragma mark -- 按钮点击方法
//取消按钮
- (void)cancelClick {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self dismissViewControllerAnimated:YES completion:^{
      [self freeArrayAndItemsInUrlArray:self.videoArray];
      [self.videoArray removeAllObjects];
    }];
  });
}

#pragma mark 切换闪光灯
- (BOOL)switchFlash{
  AVCaptureDevice *device = [self.deviceInput device];
  if ([device hasTorch]) {
    [device lockForConfiguration:nil];
    if (_isTurnON) {
      [device setTorchMode: AVCaptureTorchModeOff];//关
    } else {
      [device setTorchMode: AVCaptureTorchModeOn];//开
    }
    [device unlockForConfiguration];
    _isTurnON = !_isTurnON;
  }
  return _isTurnON;
}

#pragma mark - 切换摄像头
/**
 @return 返回bool值用于改变按钮状态
 */
- (BOOL)changeBtClick {
    bool isBackground;
    //获取当前设备
    AVCaptureDevice *currentDevice = [self.deviceInput device];
    AVCaptureDevicePosition currentPosition = [currentDevice position];
    [self removeNotificationFromDevice:currentDevice];
    AVCaptureDevice *toDevice;
    AVCaptureDevicePosition toPosition;
    if (currentPosition == AVCaptureDevicePositionUnspecified || currentPosition == AVCaptureDevicePositionFront) {
        toPosition = AVCaptureDevicePositionBack;
        isBackground = YES;
    } else {
        toPosition = AVCaptureDevicePositionFront;
        isBackground = NO;
    }
    
    toDevice = [self getCameraDeviceWithPosition:toPosition];
    [self addNotificationToDevice:toDevice];
    
    //获得要调整的设备输入对象
    NSError *error = nil;
    AVCaptureDeviceInput *toDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:toDevice error:&error];
    if (error) {
        NSLog(@"获取设备失败");
    }
    
    [self changeConfigurationWithSession:_session block:^(AVCaptureSession *session) {
        //移除原有输入对象
        [session removeInput:self.deviceInput];
        self.deviceInput = nil;
        //添加新输入对象
        if ([session canAddInput:toDeviceInput]) {
            [session addInput:toDeviceInput];
            self.deviceInput = toDeviceInput;
        }
    }];
    
    return isBackground;
}

#pragma mark - 拍照 截取照片
- (void)shutterCamera{
    AVCaptureConnection * connection = [self.imageOutPut connectionWithMediaType:AVMediaTypeVideo];
    if (!connection) {
        NSLog(@"take photo failed!");
        return;
    }
    // [videoConnection setVideoScaleAndCropFactor:_effectiveScale];

    __weak typeof(self) weakSelf = self;
  
    [self.imageOutPut captureStillImageAsynchronouslyFromConnection:connection
                                                  completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer == NULL) {
            return;
        }
        NSData * imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        
        UIImage *originImage = [[UIImage alloc] initWithData:imageData];
      
        CGSize size = CGSizeMake(weakSelf.videoPreviewLayer.bounds.size.width * 2,
                                 weakSelf.videoPreviewLayer.bounds.size.height * 2);
        
        UIImage *scaledImage = [originImage resizedImageWithContentMode:UIViewContentModeScaleAspectFill
                                                                 bounds:size
                                                   interpolationQuality:kCGInterpolationHigh];
        
        CGRect cropFrame = CGRectMake((scaledImage.size.width - size.width) / 2,
                                      (scaledImage.size.height - size.height) / 2,
                                      size.width, size.height);
        UIImage *croppedImage = nil;
        if (weakSelf.deviceInput.device.position == AVCaptureDevicePositionFront) {
            croppedImage = [scaledImage croppedImage:cropFrame
                                     WithOrientation:UIImageOrientationUpMirrored];
        }else
        {
            croppedImage = [scaledImage croppedImage:cropFrame];
        }
        //横屏时旋转image
        croppedImage = [croppedImage changeImageWithOrientation:self.orientation];
      [self saveImageToPhotoAlbum: croppedImage];
        NSLog(@"获得图片");
    }];
}

#pragma - 初始化图片设置
- (AVCaptureStillImageOutput *)imageOutPut{
    if (_imageOutPut == nil) {
        //生成输出对象
        _imageOutPut = [[AVCaptureStillImageOutput alloc] init];
        NSDictionary *myOutputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];
        [_imageOutPut setOutputSettings:myOutputSettings];
    }
    return _imageOutPut;
}

#pragma - 保存至相册
- (void)saveImageToPhotoAlbum:(UIImage*)savedImage{
  UIImageWriteToSavedPhotosAlbum(savedImage, self, nil, NULL);
  
  NSData *imageData = UIImagePNGRepresentation(savedImage);
  
  NSString *path = [self createFile: imageData];
  
  [self.dict setObject:@"拍照完成" forKey:@"msg"];
  [self.dict setObject:@200 forKey: @"code"];
  [self.dict setObject:@(bool_true) forKey: @"status"];
  [self.dict setObject:path forKey: @"data"];
  
  NSFileManager *fileManager = [NSFileManager defaultManager];
  // NSData *data = [NSData dataWithContentsOfFile:storeUrl.path];
  if ([fileManager fileExistsAtPath:path]) {
      NSLog(@"图片存在");
  } else {
      NSLog(@"图片不存在");
  }

  if (self.completionBlock) {
    self.completionBlock(self.dict);
  }
}

#pragma - 创建临时路径
- (NSString *)temporaryFilePath:(NSString *)suffix {
  NSString *fileExtension = [@"image_%@" stringByAppendingString:suffix];
  NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
  NSString *tmpFile = [NSString stringWithFormat:fileExtension, guid];
  NSString *tmpDirectory = NSTemporaryDirectory();
  NSString *tmpPath = [tmpDirectory stringByAppendingPathComponent:tmpFile];
  return tmpPath;
}

// 保存为文件
- (NSString *)createFile:(NSData *)data {
  NSString *tmpPath = [self temporaryFilePath:@".jpg"];
  if ([[NSFileManager defaultManager] createFileAtPath:tmpPath contents:data attributes:nil]) {
    return tmpPath;
  } else {
    nil;
  }
  return tmpPath;
}

#pragma - 开始录制
/**
 @return 返回bool值用于改变按钮状态
 */
- (BOOL)videoBtClick {
    //根据设备输出获得链接
    AVCaptureConnection *connection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    //根据链接取出设备输出的数据
    if (![self.movieFileOutput isRecording]) {
      self.enableRotation = NO;
      
      //如果支持多任务则开启多任务
      if ([[UIDevice currentDevice] isMultitaskingSupported]) {
          self.backgroundTaskIdentifier=[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
      }
      
      //预览图层和视频方向保持一致
      connection.videoOrientation = [self.videoPreviewLayer connection].videoOrientation;
      
      //视频防抖模式
      if ([connection isVideoStabilizationSupported]) {
          connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
      }
      
      //用日期做为视频文件名称
      NSString *str = [self getCurrentDate];
      
      NSString *outputFilePath = [NSTemporaryDirectory() stringByAppendingString:[NSString stringWithFormat:@"%@%@",str,@".mov"]];
      
      NSURL *fileUrl = [NSURL fileURLWithPath:outputFilePath];
      [self.movieFileOutput startRecordingToOutputFileURL:fileUrl recordingDelegate:self];
      return YES;
        
    }
    [self.movieFileOutput stopRecording];
    return NO;
}

#pragma - 开始合并视频
- (void)mergeClick:(void (^)(NSMutableDictionary *outPath))successBlock failure:(void (^)(NSMutableDictionary *error))failureBlcok {
  
  [_dict setObject:@"500" forKey: @"code"];
  [_dict setObject:@(bool_false) forKey: @"status"];
  [_dict setObject:@"" forKey: @"data"];
  
  if (_videoArray.count <= 0) {
//    [self noticeAlertTitle:@"请先录制视频，然后后在合并" cancel:@"确定"];
    [_dict setObject:@"请先录制视频，然后后在合并" forKey: @"msg"];
    if (failureBlcok) {
      failureBlcok(_dict);
    }
    return;
  }


  if ([self.movieFileOutput isRecording]) {
    NSLog(@"请录制完成后在合并");
//    [self noticeAlertTitle:@"请录制完成后在合并" cancel:@"确定"];
    [_dict setObject:@"请录制完成后在合并" forKey: @"msg"];
    if (failureBlcok) {
      failureBlcok(_dict);
    }
    return;
  }
  
  
//  UIAlertView *alert = [self noticeAlertTitle:@"处理中..." cancel:nil];
  NSString *pathStr = [self getCurrentDate];

  [[XDVideoManager defaultManager]
     mergeVideosToOneVideo:_videoArray
               toStorePath:pathStr
             WithStoreName:@"video"
             isSaveGallery:_isSaveGallery
            backGroundTask:_backgroundTaskIdentifier
                   success:^(NSString *info){
                      // 清空录制数组数据
                      [self.videoArray removeAllObjects];
                      
                //      // 需要在主线程中执行
                //      dispatch_async(dispatch_get_main_queue(), ^{
                //        //主线程执行
                //        [alert dismissWithClickedButtonIndex:-1 animated:YES];
                //      });
                      if (successBlock) {
                        [self.dict setObject:@"录制完成" forKey: @"msg"];
                        [self.dict setObject:@200 forKey: @"code"];
                        [self.dict setObject:@(bool_true) forKey: @"status"];
                        [self.dict setObject:info forKey: @"data"];
                        successBlock(self.dict);
                      }
                  }
                  failure:^(NSString *error){
                    NSLog(@"%@", error);
                    [self.videoArray removeAllObjects];
                  }
   ];
  return;
}

#pragma - 点击屏幕聚焦
/**
 @param view 手势所在的视图
 @param gesture 手势
 */
- (void)videoLayerClick:(SelectView *)view gesture:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:view];
    NSLog(@"位置：%f",point.y);
    CGPoint cameraPoint = [self.videoPreviewLayer captureDevicePointOfInterestForPoint:point];
    
    [self setFocusViewWithPoint:point];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
}

#pragma - 设置聚焦光标位置
/**
 @param point 光标位置
 */
-(void)setFocusViewWithPoint:(CGPoint)point{
    self.focusView.center=point;
    self.focusView.transform=CGAffineTransformMakeScale(1.5, 1.5);
    self.focusView.alpha=1.0;
    [UIView animateWithDuration:1.0 animations:^{
        self.focusView.transform=CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.focusView.alpha=0;
        
    }];
}

#pragma - 设置聚焦点
/**
 @param point 聚焦点
 */
-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:focusMode];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:exposureMode];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];
        }
    }];
}

#pragma mark -- 视频输出代理
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    NSLog(@"开始录制...");
    [_videoArray addObject:fileURL];
    NSLog(@"%@",fileURL);
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    NSLog(@"视频录制完成");
    self.enableRotation = YES;
    NSLog(@"%@",outputFileURL);
}

- ( long long ) fileSizeAtPath:( NSString *) filePath{
    NSFileManager * manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath :filePath]){
        return [[manager attributesOfItemAtPath :filePath error : nil] fileSize];
    }
    return 0;
}

- ( float ) folderSizeAtPath:( NSString *) folderPath{
    NSFileManager * manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath :folderPath]) return 0 ;
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath :folderPath] objectEnumerator];
    NSString * fileName;
    long long folderSize = 0 ;
    while ((fileName = [childFilesEnumerator nextObject]) != nil ){
        //获取文件全路径
        NSString * fileAbsolutePath = [folderPath stringByAppendingPathComponent :fileName];
        folderSize += [ self fileSizeAtPath :fileAbsolutePath];
    }
    return folderSize/( 1024.0 * 1024.0);
}

-( float )readCacheSize{
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains (NSCachesDirectory , NSUserDomainMask , YES) firstObject];
    return [self folderSizeAtPath :cachePath];
}
- (void)cleanCacheFile{
  [self cleanCaches:NSTemporaryDirectory()];
}

- (void)cleanCaches:(NSString *)path{
  // 利用NSFileManager实现对文件的管理
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if ([fileManager fileExistsAtPath:path]) {
    // 获取该路径下面的文件名
    NSArray *childrenFiles = [fileManager subpathsAtPath:path];
    for (NSString *fileName in childrenFiles) {
        // 拼接路径
        NSString *absolutePath = [path stringByAppendingPathComponent:fileName];
        // 将文件删除
        [fileManager removeItemAtPath:absolutePath error:nil];
    }
  }
}

- (void)clearFile{
    NSString * cachePath = [NSSearchPathForDirectoriesInDomains (NSCachesDirectory , NSUserDomainMask , YES ) firstObject];
    NSArray * files = [[NSFileManager defaultManager ] subpathsAtPath :cachePath];
    //NSLog ( @"cachpath = %@" , cachePath);
    
    //读取缓存大小
    float cacheSize = [self readCacheSize] ;
    NSLog(@"缓存大小:%f",cacheSize);
    //    [NSString stringWithFormat:@"%.2fKB",cacheSize];
    
    
    for ( NSString * p in files) {
        
        NSError * error = nil ;
        //获取文件全路径
        NSString * fileAbsolutePath = [cachePath stringByAppendingPathComponent :p];
        
        if ([[NSFileManager defaultManager ] fileExistsAtPath :fileAbsolutePath]) {
            [[NSFileManager defaultManager ] removeItemAtPath :fileAbsolutePath error :&error];
        }
    }
}
@end
