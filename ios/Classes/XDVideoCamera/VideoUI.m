#import "VideoUI.h"
#import "XDVideocamera.h"
#import "VideoRecordProgressView.h"


static const CGFloat KTimerInterval = 0.02;  //进度条timer
static const CGFloat KMaxRecordTime = 10;    //最大录制时间

@interface VideoUI()
@property (nonatomic, strong) SelectImageView *changeBt;
@property (nonatomic, strong) SelectImageView *videoBt;
@property (nonatomic, strong) SelectView *VideoLayerView;
@property (nonatomic, strong) UIView *focusView;
@property (nonatomic, strong) UIView *headerContent;
@property (nonatomic, strong) UIView *footerContent;

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *tipLabel;
@property (nonatomic, strong) UIView *recordBackView;
@property (nonatomic, strong) VideoRecordProgressView *progressView;
@property (nonatomic, strong) UIView *recordButton;
@property (nonatomic, strong) UIButton *flashButton;
@property (nonatomic, strong) UIButton *switchCameraButton;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIButton *finishButton;

@property (nonatomic, strong) SelectImageView *cancel;
@property (nonatomic, strong) SelectImageView *combine;
@property (nonatomic, weak) UIWindow *originKeyWindow;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) CGFloat recordTime;                              //录制时间

@end

//          maxTime: (CGRect)maxRecordTime
//          minTime: (CGRect)minRecordTime
//       flashImage: (CGRect)flashImage
//  flashImageWidth: (CGRect)flashImageWidth
// flashImageHeight: (CGRect)flashImageHeight
//      cameraImage: (CGRect)cameraImage
// cameraImageWidth: (CGRect)cameraImageWidth
//cameraImageHeight: (CGRect)cameraImageHeight
//        backImage: (CGRect)backImage
//   backImageWidth: (CGRect)backImageWidth
//  backImageHeight: (CGRect)backImageHeight
//    inCircleColor: (NSString*) inCircleColor
//   outCircleColor: (NSString*) outCircleColor
//    progressColor: (NSString*) progressColor
//          tipText: (NSString*) tipText
//  tipContinueText: (NSString*) tipContinueText
//       radiusSize: (NSString*) radiusSize
@implementation VideoUI
- (instancetype)initWithFrame: (CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
      // 隐藏状态栏
      self.backgroundColor = [UIColor blackColor];
      frame.origin.y = frame.size.height;
      self.frame = frame;
      self.originKeyWindow = [[UIApplication sharedApplication].delegate window];
      self.originKeyWindow.windowLevel = UIWindowLevelStatusBar + 1;
      
      [self creatMainUI];
    }
    return self;
}

#pragma mark - 视图
- (void)creatMainUI {
  _VideoLayerView = [[SelectView alloc]initWithFrame:CGRectMake(0,0,self.frame.size.width,self.frame.size.height)];
  _VideoLayerView.backgroundColor = [UIColor blackColor];

  [_VideoLayerView tapGestureBlock:^(UITapGestureRecognizer *gesture) {
    [self.delegate videoLayerClick:self.VideoLayerView gesture:gesture];
  }];
  
  _focusView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 60, 60)];
  _focusView.backgroundColor = [UIColor clearColor];
  _focusView.layer.borderColor = [UIColor greenColor].CGColor;
  _focusView.layer.borderWidth = 1.5;
  _focusView.alpha = 0;
  
  self.progressView.totolProgress = KMaxRecordTime;

  [_VideoLayerView addSubview:_focusView];
  [_VideoLayerView addSubview:self.recordBackView];
  [_VideoLayerView addSubview:self.tipLabel];
  [_VideoLayerView addSubview:self.progressView];
  [_VideoLayerView addSubview:self.recordBtn];
  [_VideoLayerView addSubview:self.flashBtn];
  [_VideoLayerView addSubview:self.switchCameraBtn];
  [_VideoLayerView addSubview:self.backBtn];
  [_VideoLayerView addSubview:self.deleteBtn];
  [_VideoLayerView addSubview:self.finishBtn];
  
  [self addSubview:_VideoLayerView];
}

// 底部提示文字
- (UILabel *)tipLabel{
    if (!_tipLabel) {
      _tipLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, self.recordBackView.origin.y - 30, self.width, 20)];
      _tipLabel.textColor = [UIColor whiteColor];
      _tipLabel.text = @"点击拍照, 长按录制";
      _tipLabel.textAlignment = NSTextAlignmentCenter;
      _tipLabel.font = [UIFont systemFontOfSize:12];
    }
    return _tipLabel;
}

#pragma mark - 底部
- (UIView *)recordBackView{
    if (!_recordBackView) {
        CGRect rect = self.recordBtn.frame;
        CGFloat gap = 7.5;
        rect.size = CGSizeMake(rect.size.width + gap*2, rect.size.height + gap*2);
        rect.origin = CGPointMake(rect.origin.x - gap, rect.origin.y - gap);
        _recordBackView = [[UIView alloc]initWithFrame:rect];
        _recordBackView.backgroundColor = [UIColor grayColor];
        _recordBackView.alpha = 0.6;
        [_recordBackView.layer setCornerRadius:_recordBackView.frame.size.width/2];
    }
    return _recordBackView;
}

#pragma mark - 进度条
- (VideoRecordProgressView *)progressView{
    if (!_progressView) {
        _progressView = [[VideoRecordProgressView alloc] initWithFrame:self.recordBackView.frame];
    }
    return _progressView;
}

#pragma mark - 录制按钮
-(UIView *)recordBtn{
    if (!_recordButton) {
      _recordButton = [[UIView alloc]init];
      CGFloat deta = [UIScreen mainScreen].bounds.size.width/375;
      CGFloat width = 60.0*deta;
      _recordButton.frame = CGRectMake((self.width - width)/2, self.height - 107*deta, width, width);
      [_recordButton.layer setCornerRadius:_recordButton.frame.size.width/2];
      _recordButton.backgroundColor = [UIColor whiteColor];
      // 长按事件
      UILongPressGestureRecognizer *press = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(startRecord:)];
      [_recordButton addGestureRecognizer:press];
      // 点击事件
      UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
      [_recordButton addGestureRecognizer:gesture];
      _recordButton.userInteractionEnabled = YES;
    }
    return _recordButton;
}

#pragma mark - 开始拍照
- (void)tapGesture:(UITapGestureRecognizer *)gesture {
  NSLog(@"点击了");
  [self.delegate shutterCamera];
}

#pragma mark - 开始录制
- (void)startRecord:(UILongPressGestureRecognizer *)gesture{
  // 先判断是否还有时间去录制
  if(_recordTime >= KMaxRecordTime){
    return;
  }
  if (gesture.state == UIGestureRecognizerStateBegan) {
    
    if ([self.delegate videoBtClick]) {
      NSLog(@"正在录制");
      [self startRecordAnimate: YES];
      
      CGRect rect = self.progressView.frame;
      rect.size = CGSizeMake(self.recordBackView.size.width - 3, self.recordBackView.size.height - 3);
      rect.origin = CGPointMake(self.recordBackView.origin.x + 1.5, self.recordBackView.origin.y + 1.5);
      self.progressView.frame = self.recordBackView.frame;
      
      // 点击开始时设置断点
      [self.progressView.splitList addObject:[NSNumber numberWithFloat: self.recordTime]];
      // 开始倒计时
      [self startTimer];
      
      // 切换按钮
      self.backButton.hidden = YES;
      self.flashButton.hidden = YES;
      self.tipLabel.hidden = YES;
      self.switchCameraButton.hidden = YES;
      [self switchBtn: YES];
    }
  }else if(gesture.state >= UIGestureRecognizerStateEnded){
    [self stopRecording];
  }else if(gesture.state >= UIGestureRecognizerStateCancelled){
    if (![self.delegate videoBtClick]) {
      NSLog(@"取消录制");
      [self startRecordAnimate: NO];
      [self.progressView changeRadius: NO];
    }
  }else if(gesture.state >= UIGestureRecognizerStateFailed){
    if (![self.delegate videoBtClick]) {
      NSLog(@"结束录制");
      [self startRecordAnimate: NO];
      [self.progressView changeRadius: NO];
    }
  }
}

#pragma mark - 切换状态
- (void)startRecordAnimate: (BOOL) changeStatus{
  [UIView animateWithDuration:0.2 animations:^{
    self.recordBtn.transform = CGAffineTransformMakeScale(changeStatus?0.66:1.0, changeStatus?0.66:1.0);
    self.recordBackView.transform = CGAffineTransformMakeScale(changeStatus? 6.5/5 : 1, changeStatus? 6.5/5 : 1);
    // 切换进度
    [self.progressView changeRadius: changeStatus];
  }];
}


// 闪关灯按钮
- (UIButton *)flashBtn{
    if (!_flashButton) {
        _flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_flashButton setImage:[UIImage imageNamed:@"video_flash_close"] forState:UIControlStateNormal];
        _flashButton.frame = CGRectMake(20, 20, 36, 36);
        [_flashButton addTarget:self action:@selector(clickSwitchFlash) forControlEvents:UIControlEventTouchUpInside];
    }
    return _flashButton;
}

#pragma mark - 闪关灯点击事件
- (void)clickSwitchFlash{
  BOOL openedFlash = [self.delegate switchFlash];
  [self.flashButton setImage:[UIImage imageNamed: openedFlash ? @"video_flash_open" : @"video_flash_close"] forState:UIControlStateNormal];
}

#pragma mark - 相机切换
- (UIButton *)switchCameraBtn{
    if (!_switchCameraButton) {
        _switchCameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_switchCameraButton setImage:[UIImage imageNamed:@"record_video_camera"] forState:UIControlStateNormal];
        _switchCameraButton.frame = CGRectMake(self.width - 20 - 28, 20, 30, 28);
        [_switchCameraButton addTarget:self action:@selector(clickSwitchCamera) forControlEvents:UIControlEventTouchUpInside];
    }
    return _switchCameraButton;
}

#pragma mark - 点击事件
- (void)clickSwitchCamera{
   if ([self.delegate changeBtClick]) {
       NSLog(@"后置摄像头");
   } else {
       NSLog(@"前置摄像头");
   }
}

// 返回按钮
- (UIButton *)backBtn{
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton setImage:[UIImage imageNamed:@"record_video_back"] forState:UIControlStateNormal];
        _backButton.frame = CGRectMake(60, self.recordBtn.centerY - 18, 36, 36);
        [_backButton addTarget:self action:@selector(clickBackButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

#pragma mark - 返回点击事件
- (void)clickBackButton{
  // 取消
  if (self.cancelBlock) {
      self.cancelBlock();
  }
  
  [self initData];
}

- (void)initData{
  dispatch_async(dispatch_get_main_queue(), ^{
    //主线程执行
    self.originKeyWindow.windowLevel = UIWindowLevelNormal;
  });
  
  [self.delegate cancelClick];
}

//
//#pragma mark - 弹出视图
//- (void)present{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        CGRect rect = self.frame;
//        rect.origin.y = 0;
//        [UIView animateWithDuration:0.25 animations:^{
//            self.frame = rect;
//        }];
//    });
//}


#pragma mark - 删除按钮
- (UIButton *)deleteBtn{
    if (!_deleteButton) {
      _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
      [_deleteButton setImage:[UIImage imageNamed:@"video_delete"] forState:UIControlStateNormal];
      _deleteButton.frame = CGRectMake(60, self.recordBtn.centerY - 18, 36, 36);
      [_deleteButton addTarget:self action:@selector(deleteClick) forControlEvents:UIControlEventTouchUpInside];
      _deleteButton.alpha = 0;
    }
    return _deleteButton;
}

#pragma mark - 删除点击事件
- (void)deleteClick{
  if( ![self.progressView getDeleteStatus] ){
    [self.progressView setDeleteStatus: YES];
  } else {
    [self.progressView deleteSplit];
    if( [self.progressView getSplitCount] == 0 ){
      // 返回按钮
      self.backButton.hidden = NO;
      // 闪光灯
      self.flashButton.hidden = NO;
      // 切换相机
      self.switchCameraButton.hidden = NO;
      // 提示文字
      self.tipLabel.text = @"点击拍照, 长按录制";
      self.tipLabel.hidden = NO;
      
      [self switchBtn: YES];
    }
    // 重新进度条
    self.recordTime = [self.progressView getProgress];
  }
  
  BOOL deleteStatus = [self.progressView getDeleteStatus];
  [_deleteButton setImage:[UIImage imageNamed: deleteStatus ? @"video_delete_click" : @"video_delete"] forState:UIControlStateNormal];
}

#pragma mark - 完成按钮
- (UIButton *)finishBtn{
    if (!_finishButton) {
      _finishButton = [UIButton buttonWithType:UIButtonTypeCustom];
      [_finishButton setImage:[UIImage imageNamed:@"video_finish"] forState:UIControlStateNormal];
      _finishButton.frame = CGRectMake(self.width, self.recordBtn.centerY - 18, 36, 36);
      [_finishButton addTarget:self action:@selector(finishClick) forControlEvents:UIControlEventTouchUpInside];
      _finishButton.alpha = 0;
    }
    return _finishButton;
}

#pragma mark - 完成点击事件
- (void)finishClick{
  __weak typeof(self) weakSelf = self;
  [self.delegate mergeClick:^(NSMutableDictionary *info){
    // 清空断点数组
    [weakSelf.progressView cleanSplit];
    // 清空进度条
    weakSelf.progressView.progress = 0.0;
    weakSelf.recordTime = 0.0;
    
    dispatch_async(dispatch_get_main_queue(), ^{
      //主线程执行
      weakSelf.tipLabel.text = @"点击拍照, 长按录制";
      weakSelf.backButton.hidden = NO;
      weakSelf.tipLabel.hidden = NO;
      weakSelf.flashButton.hidden = NO;
      weakSelf.switchCameraButton.hidden = NO;
      
      weakSelf.deleteButton.alpha = 0;
      weakSelf.finishButton.alpha = 0;
    });
    
    if (self.completionBlock) {
        self.completionBlock(info);
    }
    
    [self initData];
   } failure:^(NSMutableDictionary *error){
     NSLog(@"失败%@", error);
     if (self.cancelBlock) {
         self.cancelBlock();
     }
  }];
}

#pragma mark - 切换动画按钮
- (void) switchBtn: (BOOL) switchType{
  self.deleteBtn.hidden = switchType;
  self.finishBtn.hidden = switchType;
  
  CGFloat deta = [UIScreen mainScreen].bounds.size.width/375.0;
  CGFloat width = 36.0*deta;
  CGRect deleteRect = _deleteButton.frame;
  CGRect finshRect = _finishButton.frame;
  deleteRect.origin.x = 60*deta;
  finshRect.origin.x = self.width - 60*deta - width;
  
  [UIView animateWithDuration:0.2 animations:^{
    self.deleteBtn.frame = deleteRect;
    self.finishBtn.frame = finshRect;
    self.deleteButton.alpha = switchType ? 0 : 1;
    self.finishButton.alpha = switchType ? 0 : 1;
  }];
}

- (void)viewsLinkBlock:(neededViewBlock)block {
    if (block) {
        block(_focusView,_VideoLayerView);
    }
}

#pragma mark - 结束录制
- (void) stopRecording{
  if (![self.delegate videoBtClick]) {
    NSLog(@"结束录制");
    [self startRecordAnimate: NO];
    // 显示闪光灯、切换相机、删除、完成
    self.tipLabel.text = @"长按继续录制";
    self.tipLabel.hidden = NO;
    self.flashButton.hidden = NO;
    self.switchCameraButton.hidden = NO;
    
    // 结束倒计时
    [self stopTimer];
    
    [self switchBtn: NO];
  }
}

#pragma mark 计时器相关
- (NSTimer *)timer{
  if (!_timer){
    _timer = [NSTimer scheduledTimerWithTimeInterval:KTimerInterval target:self selector:@selector(fire:) userInfo:nil repeats:YES];
  }
  return _timer;
}

// 倒计时进行中
- (void)fire:(NSTimer *)timer{
  self.recordTime += KTimerInterval;
  self.progressView.progress = self.recordTime;
  if(_recordTime >= KMaxRecordTime){
    [self stopRecording];
  }
}

// 开始倒计时
- (void)startTimer{
  [self.timer invalidate];
  self.timer = nil;
  [self.timer fire];
}

// 关闭倒计时
- (void)stopTimer{
  [self.timer invalidate];
  self.timer = nil;
}

@end
