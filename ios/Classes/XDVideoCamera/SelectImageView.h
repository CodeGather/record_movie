//
//  SelectImageView.h
//  二级界面
//
//  Created by 谢兴达 on 16/9/19.
//  Copyright © 2016年 谢兴达. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SelectImageView : UIImageView

- (void)tapGestureBlock:(void(^)(id obj))action;

- (void)doubleTapGestureBlock:(void(^)(id obj))action;

@end
