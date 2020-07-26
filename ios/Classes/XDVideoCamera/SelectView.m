//
//  SelectView.m
//  二级界面
//
//  Created by 谢兴达 on 16/9/19.
//  Copyright © 2016年 谢兴达. All rights reserved.
//  自定义可点击视图

#import "SelectView.h"

@interface SelectView ()
@property (nonatomic, copy) void(^action)(UITapGestureRecognizer *gesture);

@end

@implementation SelectView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

-(void)tapGestureBlock:(void (^)(UITapGestureRecognizer *gesture))action {
    if (action) {
        self.action = [action copy];
    }
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tap:)];
    [self addGestureRecognizer:tap];
}

- (void)tap:(UITapGestureRecognizer *)gesture {
    if (self.action) {
        self.action(gesture);
    }
}

@end
