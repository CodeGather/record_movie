//
//  XDVideocamera.h
//  摄像
//  作者：谢兴达（XD）
//  Created by 谢兴达 on 2017/3/1.
//  Copyright © 2017年 谢兴达. All rights reserved.
//  github链接：https://github.com/Xiexingda/XDVideoCamera.git

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "UIView+JCAddition.h"
#import "UIImage+Resize.h"

//@protocol XDVideocameraDelegate <NSObject>
////录制时间
//- (void)recordTimeCurrentTime:(CGFloat)currentTime totalTime:(CGFloat)totalTime;
////录制时间
//- (void)setSplit:(CGFloat)splitValue;
////录制时间
//- (void)clickBtn;
//@end


typedef void(^XDVideocameraDismissBlock)(void);
typedef void(^XDVideocameraCompletionBlock)(NSMutableDictionary *fileData);

@interface XDVideocamera : UIViewController
@property (assign,nonatomic) BOOL isSaveGallery;         //是否需要保存相册
@property (assign,nonatomic) CGFloat KMaxRecordTime;         // 最大录制时间
//@property (nonatomic, weak) id<XDVideocameraDelegate> delegate;
// 用于回调事件
@property (nonatomic, copy) XDVideocameraDismissBlock cancelBlock;
//if (self.cancelBlock && cancel) {
//    self.cancelBlock();
//}
@property (nonatomic, copy) XDVideocameraCompletionBlock completionBlock;

- (void)cleanCacheFile;

@end

//https://github.com/Xiexingda/XDVideoCamera.git
