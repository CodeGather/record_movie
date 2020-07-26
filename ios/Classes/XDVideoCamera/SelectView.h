//
//  SelectView.h
//  二级界面
//
//  Created by 谢兴达 on 16/9/19.
//  Copyright © 2016年 谢兴达. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SelectView : UIView

- (void)tapGestureBlock:(void(^)(UITapGestureRecognizer *gesture))action;

@end
