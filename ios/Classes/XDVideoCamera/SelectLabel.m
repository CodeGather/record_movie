//
//  SelectLabel.m
//  二级界面
//
//  Created by 谢兴达 on 2016/10/28.
//  Copyright © 2016年 谢兴达. All rights reserved.
//  自定义可点击label

#import "SelectLabel.h"

@interface SelectLabel ()
@property (nonatomic, copy) void (^action)(id);

@end

@implementation SelectLabel

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
    }
    
    return self;
}

-(instancetype)init {
    self = [super init];
    if (self) {
        self.userInteractionEnabled = YES;
    }
    
    return self;
}

- (void)tapGestureBlock:(void (^)(id))action {
    if (action) {
        _action = [action copy];
    }
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tap)];
    
    [self addGestureRecognizer:tap];
}

- (void)tap {
    if (_action) {
        _action(self);
    }
}

@end
