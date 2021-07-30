/*
 * @Author: 21克的爱情
 * @Date: 2017-06-02 16:22:13
 * @Email: raohong07@163.com
 * @LastEditors: 21克的爱情
 * @LastEditTime: 2020-08-09 00:19:43
 * @Description: 
 */ 
#import <UIKit/UIKit.h>
#import "SelectView.h"
#import "SelectImageView.h"
#import "UIView+JCAddition.h"

typedef void (^neededViewBlock)(UIView *focusView, SelectView *previewView);
typedef void(^VideoUIDismissBlock)(void);
typedef void(^VideoUICompletionBlock)(NSMutableDictionary *fileData);

/**
 代理方法
 */
@protocol VideoUIDelegate <NSObject>
- (void)initWithFrame:(CGRect)frame;
- (void)cancelClick;
- (BOOL)changeBtClick;
- (BOOL)switchFlash;
- (BOOL)videoBtClick;
- (void)present;
- (void)mergeClick:(void (^)(NSMutableDictionary *info))successBlock failure:(void (^)(NSMutableDictionary *error))failureBlcok;
- (void)shutterCamera;
- (void)videoLayerClick:(SelectView *)view gesture:(UITapGestureRecognizer *)gesture;
@end

@interface VideoUI : UIView
@property (assign,nonatomic) CGFloat KMaxRecordTime;         // 最大录制时间

// 用于其他地方调用
@property (nonatomic, weak) id<VideoUIDelegate> delegate;

// 用于回调事件
@property (nonatomic, copy) VideoUIDismissBlock cancelBlock;
//if (self.cancelBlock && cancel) {
//    self.cancelBlock();
//}
@property (nonatomic, copy) VideoUICompletionBlock completionBlock;
//if (instance.completionBlock && instance.recordVideoOutPutUrl) {
//    instance.completionBlock(instance.recordVideoOutPutUrl);
//}
//_recordView.cancelBlock = ^{
//
//};
//_recordView.completionBlock = ^(NSURL *fileUrl) {
//
//};

- (void)viewsLinkBlock:(neededViewBlock)block;
- (void)setFormData: (NSMutableDictionary *)formData;

@end
