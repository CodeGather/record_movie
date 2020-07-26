#import <UIKit/UIKit.h>

@interface VideoRecordProgressView : UIView
@property (nonatomic, assign) CGFloat totolProgress;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) CGFloat splitValue;
@property (nonatomic, retain) NSMutableArray *splitList;
@property (nonatomic, assign) BOOL deleteStatus;
@property (nonatomic, assign) BOOL isChangeRaidus;

// 切换闪光灯
//- (void)setSplit:(CGFloat)splitValue;
// 切换按钮
- (void)changeRadius:(BOOL) changeStatus;
// 获取删除状态
- (BOOL)getDeleteStatus;
// 删除断点
- (void)deleteSplit;
// 清空断点
- (void)cleanSplit;
// 获取断点个数
- (NSInteger)getSplitCount;
// 获取进度
- (CGFloat)getProgress;
@end
