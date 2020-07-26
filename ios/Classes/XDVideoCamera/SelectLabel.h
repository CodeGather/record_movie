//
//  SelectLabel.h
//  二级界面
//
//  Created by 谢兴达 on 2016/10/28.
//  Copyright © 2016年 谢兴达. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SelectLabel : UILabel

- (void)tapGestureBlock:(void(^)(id obj))action;

@end
