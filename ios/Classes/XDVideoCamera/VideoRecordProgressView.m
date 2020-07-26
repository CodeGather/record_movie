#import "VideoRecordProgressView.h"
#import "UIView+JCAddition.h"
#import "UIColor+Hex.h"

@implementation VideoRecordProgressView


-(instancetype)init{
    if (self = [super init]) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame{
  if (self = [super initWithFrame:frame]) {
      self.backgroundColor = [UIColor clearColor];
      self.clipsToBounds = NO;
  }
  _splitList = [[NSMutableArray alloc]init];
  _isChangeRaidus = NO;
  _deleteStatus = NO;
  return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
  [super drawRect:rect];
  CGContextRef ctx = UIGraphicsGetCurrentContext();//获取上下文
  
  CGPoint center = CGPointMake(self.width/2, self.height/2); //设置圆心位置
  CGFloat radius = !_isChangeRaidus ? self.width/2 - 13 : self.width/2 - 2; //设置半径
  CGFloat startA = - M_PI_2; //圆起点位置
  CGFloat endA = -M_PI_2 + M_PI * 2 * _progress/10; //圆终点位置
    
  // 绘制进度
  [[UIColor colorWithHex:0xe60044] set]; // 颜色
  CGContextSetLineWidth(ctx, 4); //设置线条宽度
  CGContextAddArc(ctx, center.x, center.y, radius, startA, endA, 0);
  CGContextStrokePath(ctx); //渲染
  
  // 2.画圆弧 绘制断点
  // 3.修饰
  [[UIColor colorWithHex:0x00f1f3] set]; // 颜色
  for (int i = 0; i < [_splitList count]; i++) {
    CGFloat itemData = [[_splitList objectAtIndex:i] floatValue];
    if( itemData > 0 ){
      CGFloat srartSplit = -M_PI_2 + M_PI * 2 * itemData/self.totolProgress; //圆终点位置
      CGFloat endSplit = -M_PI_2 + M_PI * 2 * (itemData+self.totolProgress/200)/self.totolProgress; //圆终点位置
      
      /*
      * 参数一: 上下文
      * 参数二: 中心点x
      * 参数三: 中心点y
      * 参数四: 半径
      * 参数五: 开始弧度
      * 参数六: 结束弧度
      * 参数七: 0为顺时针，1为逆时针
      */
      CGContextAddArc(ctx, center.x, center.y, radius, srartSplit, endSplit, 0);
      // 4.渲染
      CGContextStrokePath(ctx);
    }
  }
      
  //    //绘制删除模式的段落
  //    if(_deleteStatus && splitList.size()>0){
  //        float split = splitList.get(splitList.size() - 1);
  //        canvas.drawArc(oval, 270+split, girthPro -split, false, paintDelete);
  //    }
  
}

#pragma 设置进度
-(void)changeRadius: (BOOL) changeStatus{
  _isChangeRaidus = changeStatus;
  [self setNeedsDisplay];
}

#pragma 设置进度
-(void)setProgress:(CGFloat)progress{
  _progress = progress;

  dispatch_async(dispatch_get_main_queue(), ^{
    //主线程执行
    [self setNeedsDisplay];
  });
}

#pragma 获取进度
-(CGFloat)getProgress{
  return _progress;
}

#pragma 设置断点
-(void)setSplitValue:(CGFloat)splitValue{
  [_splitList addObject:[NSNumber numberWithFloat: splitValue]];
}

#pragma 获取断点
-(NSInteger)getSplitCount{
  return [_splitList count];
}

#pragma 删除断点
-(void)deleteSplit{
  // 判断是否还有断点，否则清空进度
  NSInteger count = [_splitList count];
  // 重新设置进度条
  if( count > 0){
    [self setProgress: [[_splitList lastObject] floatValue]];
  } else {
    [self setProgress: 0.0];
  }
  
  [_splitList removeLastObject];
}

#pragma 清空断点
-(void)cleanSplit{
  [_splitList removeAllObjects];
  [self setProgress: 0.0];
}

#pragma 设置删除模式
-(void)setDeleteStatus:(BOOL)isDeleteModeStatus{
  _deleteStatus = isDeleteModeStatus;
}

#pragma 是否正在删除模式
-(BOOL)getDeleteStatus{
    return _deleteStatus;
}
@end
