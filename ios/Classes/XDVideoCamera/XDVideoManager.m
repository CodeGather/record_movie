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
                      failure:(void (^)(NSString *error))failureBlcok
{
    AVMutableComposition *mixComposition = [self mergeVideostoOnevideo:tArray];
    NSURL *outputFileUrl = [self joinStorePaht:storePath togetherStoreName:storeName];
  
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
- (AVMutableComposition *)mergeVideostoOnevideo:(NSArray*)array
{
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    AVMutableCompositionTrack *a_compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableCompositionTrack *a_compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    Float64 tmpDuration =0.0f;
    
    for (NSURL *videoUrl in array)
    {
        
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
- (NSURL *)joinStorePaht:(NSString *)sPath togetherStoreName:(NSString *)sName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [paths objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *storePath = [documentPath stringByAppendingPathComponent:sPath];
    BOOL isExist = [fileManager fileExistsAtPath:storePath];
    if(!isExist){
        [fileManager createDirectoryAtPath:storePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *realName = [NSString stringWithFormat:@"%@.mov", sName];
    storePath = [storePath stringByAppendingPathComponent:realName];
    
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
                          failure:(void (^)(NSString *error))failureBlcok
{
    AVAssetExportSession* _assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    _assetExport.outputFileType = AVFileTypeQuickTimeMovie;
    _assetExport.outputURL = storeUrl;
    
    __block typeof(task) blockTask = task;
  
  if( isSaveGallery ){
    [_assetExport exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //写入系统相册
            ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc]init];
            [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:storeUrl completionBlock:^(NSURL *assetURL, NSError *error) {
                [[StoreFileManager defaultManager] removeItemAtPath:[storeUrl path]];
                [self freeFilesInArray:files];
                
                //通知后台挂起
                if (blockTask != UIBackgroundTaskInvalid) {
                    [[UIApplication sharedApplication] endBackgroundTask:blockTask];
                    blockTask = UIBackgroundTaskInvalid;
                }

                if (error) {
                    if (failureBlcok) {
                        NSString *errorStr = [NSString stringWithFormat:@"存入相册失败:%@",error.localizedDescription];
                        failureBlcok(errorStr);
                    }
                    
                } else {
                    if (successBlock) {
                        NSString *successStr = [NSString stringWithFormat:@"%@",assetURL];
                        successBlock(successStr);
                    }
                }
            }];
        });
    }];
  } else {
    if (successBlock) {
        NSString *successStr = [NSString stringWithFormat:@"%@",storeUrl];
        successBlock(successStr);
    }
  }
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
