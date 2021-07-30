//
//  XDVideoManager.m
//  摄像
//
//  Created by 谢兴达 on 2017/3/23.
//  Copyright © 2017年 谢兴达. All rights reserved.
//

#import "XDVideoManager.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import "StoreFileManager.h"
#import "SDAVAssetExportSession.h"
#import <Photos/Photos.h>

@interface XDVideoManager()
@property (nonatomic, strong) SDAVAssetExportSession* assetExportVideo;
@end

@implementation XDVideoManager

/**
 单利模式

 @return self
 */
+ (XDVideoManager *)defaultManager {
    static XDVideoManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!manager) {
            manager = [[XDVideoManager alloc]init];
        }
    });
    return manager;
}

- (void)mergeVideosToOneVideo:(NSArray *)tArray
                  toStorePath:(NSString *)storePath
                WithStoreName:(NSString *)storeName
                isSaveGallery:(BOOL) isSaveGallery
               backGroundTask:(UIBackgroundTaskIdentifier)task
                      success:(void (^)(NSString *info))successBlock
                      failure:(void (^)(NSString *error))failureBlcok{
  _waittingAlert = [self showWaitingAlert];
  
  AVMutableComposition *mixComposition = [self mergeVideostoOnevideoArray:tArray];
  NSURL *outputFileUrl = [self joinStorePath:storeName];
//  NSURL *outputFileUrl = [self joinStorePaht:storePath togetherStoreName:storeName];
  [self storeAVMutableComposition:mixComposition
                     withStoreUrl:outputFileUrl
                         WihtName:storeName
                    isSaveGallery: isSaveGallery
                   backGroundTask:(UIBackgroundTaskIdentifier)task
                       filesArray:tArray
                          success:successBlock
                          failure:failureBlcok
   ];
}

/**
 多个视频合成为一个
 
 @param array 多个视频的NSURL地址
 
 @return 返回AVMutableComposition
 */
- (AVMutableComposition *)mergeVideostoOnevideoArray:(NSArray*)array{
  dispatch_async(dispatch_get_main_queue(), ^{
    //主线程执行
    self->_waittingAlert.message = @"视频正在合并中...";
  });
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    AVMutableCompositionTrack *a_compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableCompositionTrack *a_compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    Float64 tmpDuration =0.0f;
    
    for (NSURL *videoUrl in array){
        
        AVURLAsset *asset = [[AVURLAsset alloc]initWithURL:videoUrl options:nil];
        
        AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        AVAssetTrack *audioAssetTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    
        CMTimeRange video_timeRange = CMTimeRangeMake(kCMTimeZero,asset.duration);
        
        [a_compositionVideoTrack setPreferredTransform:videoAssetTrack.preferredTransform];
        [a_compositionAudioTrack setPreferredTransform:audioAssetTrack.preferredTransform];

        /**
         依次加入每个asset
        
         param TimeRange 加入的asset持续时间
         param Track     加入的asset类型,这里都是video
         param Time      从哪个时间点加入asset,这里用了CMTime下面的CMTimeMakeWithSeconds(tmpDuration, 0),timesacle为0
         */
        NSError *error;
        [a_compositionVideoTrack insertTimeRange:video_timeRange ofTrack:videoAssetTrack atTime:CMTimeMakeWithSeconds(tmpDuration, 0) error:&error];
        
        
        [a_compositionAudioTrack insertTimeRange:video_timeRange ofTrack:audioAssetTrack atTime:CMTimeMakeWithSeconds(tmpDuration, 0) error:&error];
        tmpDuration += CMTimeGetSeconds(asset.duration);
    }
    return mixComposition;
}

/**
 拼接url地址

 @param sPath sPath 沙盒文件夹名
 @param sName sName 文件名称
 @return 返回拼接好的url地址
 */
- (NSURL *)joinStorePaht:(NSString *)sPath togetherStoreName:(NSString *)sName{
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentPath = [paths objectAtIndex:0];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  
  NSString *storePath = [documentPath stringByAppendingPathComponent:sPath];
  BOOL isExist = [fileManager fileExistsAtPath:storePath];
  if(!isExist){
      [fileManager createDirectoryAtPath:storePath withIntermediateDirectories:YES attributes:nil error:nil];
  }
  NSString *realName = [NSString stringWithFormat:@"%@.mp4", sName];
  storePath = [storePath stringByAppendingPathComponent:realName];
  
  [[StoreFileManager defaultManager] removeItemAtPath:storePath];
  
  NSURL *outputFileUrl = [NSURL fileURLWithPath:storePath];
  
  return outputFileUrl;
}

/**
 拼接url地址

 @param sName sName 文件名称
 @return 返回拼接好的url地址
 */
- (NSURL *)joinStorePath:(NSString *)sName{
  NSString *documentPath = NSTemporaryDirectory();
  
  NSString *realName = [NSString stringWithFormat:@"%@.mp4", sName];
  NSString *storePath = [documentPath stringByAppendingPathComponent:realName];
  
  [[StoreFileManager defaultManager] removeItemAtPath:storePath];
  
  NSURL *outputFileUrl = [NSURL fileURLWithPath:storePath];
  
  return outputFileUrl;
}


/**
 存储合成的视频

 @param mixComposition mixComposition参数
 @param storeUrl 存储的路径
 @param aName 视频名称
 @param task 后台标识
 @param files 视频URL路径数组
 @param successBlock 成功回调
 @param failureBlcok 失败回调
 */
- (void)storeAVMutableComposition:(AVMutableComposition*)mixComposition
                     withStoreUrl:(NSURL *)storeUrl
                         WihtName:(NSString *)aName
                    isSaveGallery:(BOOL) isSaveGallery
                   backGroundTask:(UIBackgroundTaskIdentifier)task
                       filesArray:(NSArray *)files
                          success:(void (^)(NSString *outPath))successBlock
                          failure:(void (^)(NSString *error))failureBlcok{
  dispatch_async(dispatch_get_main_queue(), ^{
    //主线程执行
    self->_waittingAlert.message = @"视频正在压缩中...";
  });
//  NSURL *outPath = [self joinStorePath:[self getCurrentDate]];
  
  _assetExportVideo = [SDAVAssetExportSession.alloc initWithAsset:mixComposition];
  
  _assetExportVideo.outputFileType = AVFileTypeMPEG4;
  _assetExportVideo.outputURL = storeUrl;
  
  _assetExportVideo.videoSettings = @{
      AVVideoCodecKey: AVVideoCodecH264,
      AVVideoWidthKey: @1080,
      AVVideoHeightKey: @1920,
      AVVideoCompressionPropertiesKey: @{
          AVVideoAverageBitRateKey: @2000000,
          AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
      },
  };
  _assetExportVideo.audioSettings = @{
      AVFormatIDKey: @(kAudioFormatMPEG4AAC),
      AVNumberOfChannelsKey: @2,
      AVSampleRateKey: @24000,
      AVEncoderBitRateKey: @32000,
  };
  
  __block typeof(task) blockTask = task;

  [_assetExportVideo exportAsynchronouslyWithCompletionHandler:^{

    [self dismissWaitingAlert:self->_waittingAlert];
    
    if (self->_assetExportVideo.status == AVAssetExportSessionStatusCompleted) {
      NSLog(@"视频压缩后大小-------------- %f",[[NSData dataWithContentsOfURL:storeUrl] length]/1024.00 /1024.00);
      NSLog(@"Video export succeeded");
      
      if( isSaveGallery ){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          NSLog(@"视频大小-------------- %f",[[NSData dataWithContentsOfURL:storeUrl] length]/1024.00 /1024.00);
          //写入系统相册
          ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc]init];
          [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:storeUrl completionBlock:^(NSURL *assetURL, NSError *error) {
            // 删除沙盒的图片
            // [[StoreFileManager defaultManager] removeItemAtPath:[storeUrl path]];
            [self freeFilesInArray:files];
            
            //通知后台挂起
            if (blockTask != UIBackgroundTaskInvalid) {
                [[UIApplication sharedApplication] endBackgroundTask:blockTask];
                blockTask = UIBackgroundTaskInvalid;
            }

            if (error) {
              // 删除弹窗
              [self dismissWaitingAlert:self.waittingAlert];

              if (failureBlcok) {
                  NSString *errorStr = [NSString stringWithFormat:@"存入相册失败:%@",error.localizedDescription];
                  failureBlcok(errorStr);
              }

            } else {
                if (successBlock) {
                  NSFileManager *fileManager = [NSFileManager defaultManager];
                  // NSData *data = [NSData dataWithContentsOfFile:storeUrl.path];
                  if ([fileManager fileExistsAtPath:storeUrl.path]) {
                      NSLog(@"录制视频存在");
                  } else {
                      NSLog(@"录制视频不存在");
                  }
                  // 删除弹窗
                  [self dismissWaitingAlert:self->_waittingAlert];

                  NSString *successStr = [NSString stringWithFormat:@"%@",storeUrl.path];
                  successBlock(successStr);
                }
            }
          }];
        });
      } else {
        if (successBlock) {
          NSFileManager *fileManager = [NSFileManager defaultManager];
          if ([fileManager fileExistsAtPath:storeUrl.path]) {
              NSLog(@"录制视频存在");
          } else {
              NSLog(@"录制视频不存在");
          }
          
          // 删除弹窗
          [self dismissWaitingAlert:self.waittingAlert];
          
          NSString *successStr = [NSString stringWithFormat:@"%@",storeUrl.path];
          successBlock(successStr);
        }
      }
      
    }  else if (self->_assetExportVideo.status == AVAssetExportSessionStatusCancelled) {
        NSLog(@"Video export cancelled");
      if (failureBlcok) {
          failureBlcok(@"cancel");
      }
    } else {
      NSLog(@"Video export failed with error: %@ (%ld)", self->_assetExportVideo.error.localizedDescription, (long)self->_assetExportVideo.error.code);
      if (failureBlcok) {
        NSString *errorStr = [NSString stringWithFormat:@"存入相册失败:%@",self->_assetExportVideo.error.localizedDescription];
        failureBlcok(errorStr);
      }
    }
  }];
  
//
//  // 控制压缩等级
//  _assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPreset1280x720];
//  // 控制视频格式
//  // _assetExport.outputFileType = AVFileTypeQuickTimeMovie;
//  _assetExport.outputFileType = AVFileTypeMPEG4;
//  _assetExport.shouldOptimizeForNetworkUse = YES;
//  _assetExport.outputURL = storeUrl;
//
//  __block typeof(task) blockTask = task;
//
//  [_assetExport exportAsynchronouslyWithCompletionHandler:^{
//    [self yaSuoShiPinWithfilepath: storeUrl
//                         success:successBlock
//                         failure:failureBlcok
//    ];
//
//    [self startTimer];
//
//    dispatch_async(dispatch_get_main_queue(), ^{
//      self->_waittingAlert.message = @"转换成功";
//    });
//
//    if( isSaveGallery ){
//      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        NSLog(@"视频大小-------------- %f",[[NSData dataWithContentsOfURL:storeUrl] length]/1024.00 /1024.00);
//        //写入系统相册
//        ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc]init];
//        [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:storeUrl completionBlock:^(NSURL *assetURL, NSError *error) {
//          // 删除沙盒的图片
//          // [[StoreFileManager defaultManager] removeItemAtPath:[storeUrl path]];
//          [self freeFilesInArray:files];
//
//          //通知后台挂起
//          if (blockTask != UIBackgroundTaskInvalid) {
//              [[UIApplication sharedApplication] endBackgroundTask:blockTask];
//              blockTask = UIBackgroundTaskInvalid;
//          }
//
//          if (error) {
//            // 删除弹窗
//            [self dismissWaitingAlert:self.waittingAlert];
//
//            if (failureBlcok) {
//                NSString *errorStr = [NSString stringWithFormat:@"存入相册失败:%@",error.localizedDescription];
//                failureBlcok(errorStr);
//            }
//
//          } else {
//              if (successBlock) {
//                NSFileManager *fileManager = [NSFileManager defaultManager];
//                // NSData *data = [NSData dataWithContentsOfFile:storeUrl.path];
//                if ([fileManager fileExistsAtPath:storeUrl.path]) {
//                    NSLog(@"录制视频存在");
//                } else {
//                    NSLog(@"录制视频不存在");
//                }
//                // 删除弹窗
//                [self dismissWaitingAlert:self->_waittingAlert];
//
//                NSString *successStr = [NSString stringWithFormat:@"%@",storeUrl.path];
//                successBlock(successStr);
//              }
//          }
//        }];
//      });
//    } else {
//      if (successBlock) {
//        NSFileManager *fileManager = [NSFileManager defaultManager];
//        if ([fileManager fileExistsAtPath:storeUrl.path]) {
//            NSLog(@"录制视频存在");
//        } else {
//            NSLog(@"录制视频不存在");
//        }
//
//        // 删除弹窗
//        [self dismissWaitingAlert:self.waittingAlert];
//
//        NSString *successStr = [NSString stringWithFormat:@"%@",storeUrl.path];
//        successBlock(successStr);
//      }
//    }
//  }];

}



#pragma mark 计时器相关
- (NSTimer *)timer{
  if (!_timer){
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(fire:) userInfo:nil repeats:YES];
  }
  return _timer;
}

// 倒计时进行中
- (void)fire:(NSTimer *)timer{
  
  float progress = _assetExportVideo.progress;
  NSLog(@"---------------------------%f",progress);
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

-(UIAlertView *)showWaitingAlert{
    UIAlertView *waittingAlert = [
     [UIAlertView alloc] initWithTitle: @"请稍候"
                               message: @"正在转换视频"
                              delegate: nil
                     cancelButtonTitle: nil
                     otherButtonTitles: nil];
    
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
//    activityView.frame = CGRectMake(400, 400, 400, 400);
//  
//    [waittingAlert addSubview:activityView];
  
    [activityView startAnimating];
    
    [waittingAlert show];
      
    return waittingAlert;
  
}
- (void) dismissWaitingAlert: (UIAlertView* )waittingAlert{
  if (waittingAlert != nil) {
    dispatch_async(dispatch_get_main_queue(), ^{
      //主线程执行
      [waittingAlert dismissWithClickedButtonIndex:0 animated:YES];
    });
  }
}

- (void)yaSuoShiPinWithfilepath:(NSURL *)filepath
                        success:(void (^)(NSString *outPath))successBlock
                        failure:(void (^)(NSString *error))failureBlcok{
  AVURLAsset *asset = [AVURLAsset URLAssetWithURL:filepath options:nil];
  
  
  NSURL *outPath = [self joinStorePath:[self getCurrentDate]];
  
  _assetExportVideo = [SDAVAssetExportSession.alloc initWithAsset:asset];
  
  _assetExportVideo.outputFileType = AVFileTypeMPEG4;
  _assetExportVideo.outputURL = outPath;
  
  _assetExportVideo.videoSettings = @{
      AVVideoCodecKey: AVVideoCodecH264,
      AVVideoWidthKey: @1280,
      AVVideoHeightKey: @720,
      AVVideoCompressionPropertiesKey: @{
          AVVideoAverageBitRateKey: @6000000,
          AVVideoProfileLevelKey: AVVideoProfileLevelH264High40,
      },
  };
  _assetExportVideo.audioSettings = @{
      AVFormatIDKey: @(kAudioFormatMPEG4AAC),
      AVNumberOfChannelsKey: @2,
      AVSampleRateKey: @24000,
      AVEncoderBitRateKey: @128000,
  };

  [_assetExportVideo exportAsynchronouslyWithCompletionHandler:^{

    [self dismissWaitingAlert:self->_waittingAlert];
    
    if (self->_assetExportVideo.status == AVAssetExportSessionStatusCompleted) {
      NSLog(@"视频压缩后大小-------------- %f",[[NSData dataWithContentsOfURL:outPath] length]/1024.00 /1024.00);
      NSLog(@"Video export succeeded");
      
      if (successBlock) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:outPath.path]) {
            NSLog(@"录制视频存在");
        } else {
            NSLog(@"录制视频不存在");
        }
        
        NSString *successStr = [NSString stringWithFormat:@"%@",outPath.path];
        successBlock(successStr);
      }
      
    }  else if (self->_assetExportVideo.status == AVAssetExportSessionStatusCancelled) {
        NSLog(@"Video export cancelled");
      if (failureBlcok) {
          failureBlcok(@"cancel");
      }
    } else {
      NSLog(@"Video export failed with error: %@ (%ld)", self->_assetExportVideo.error.localizedDescription, (long)self->_assetExportVideo.error.code);
      if (failureBlcok) {
        NSString *errorStr = [NSString stringWithFormat:@"存入相册失败:%@",self->_assetExportVideo.error.localizedDescription];
        failureBlcok(errorStr);
      }
    }
  }];
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
获取链接的参数

@param url 存放视频URL路径的数组
*/
- (NSMutableDictionary *) getKeyValue:(NSURL *) url{
  NSLog(@"--------------------------%@",url.query);
  NSArray *keyValues = [url.query componentsSeparatedByString:@"&"];//[[NSString stringWithFormat:@"%@",url.pathExtension] componentsSeparatedByString:@"&"];
  NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
  
  for (NSString *keyValue in keyValues) {
    NSArray *arr = [keyValue componentsSeparatedByString:@"="];
    if([arr count] > 0){
      [dic setValue:arr[1] forKey:arr[0]];
    }
  }
  
  return dic;
}

/**
 释放缓存

 @param filesArray 存放视频URL路径的数组
 */
- (void)freeFilesInArray:(NSArray *)filesArray {
    for (NSURL *fileUrl in filesArray) {
        [[StoreFileManager defaultManager] removeItemAtUrl:fileUrl];
    }
}

@end
