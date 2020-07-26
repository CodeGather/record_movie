//
//  SelectImageView.m
//  二级界面
//
//  Created by 谢兴达 on 16/9/19.
//  Copyright © 2016年 谢兴达. All rights reserved.
//  自定义可点击imageView

#import "SelectImageView.h"

@interface SelectImageView()
@property (nonatomic, strong) UITapGestureRecognizer *tap;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTap;


@property (nonatomic, copy) void (^action)(id obj);
@property (nonatomic, copy) void (^doubleAction)(id obj);

@end

@implementation SelectImageView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (void)tapGestureBlock:(void(^)(id obj))action {
    self.action = [action copy];
    _tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tap:)];
    _tap.delaysTouchesBegan = YES;
    _tap.numberOfTapsRequired = 1;
    [self addGestureRecognizer:_tap];
    
}

- (void)doubleTapGestureBlock:(void (^)(id))action {
    self.doubleAction = [action copy];
    _doubleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTap:)];
    _doubleTap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:_doubleTap];
    if (_tap) {
        [_tap requireGestureRecognizerToFail:_doubleTap];
    }
}

- (void)tap:(UITapGestureRecognizer *)tap {
    if (self.action) {
        self.action(tap);
    }
}


- (void)doubleTap:(UITapGestureRecognizer *)tap {
    if (_doubleAction) {
        self.doubleAction(tap);
    }
}

@end
