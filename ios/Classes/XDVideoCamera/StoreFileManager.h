//
//  StoreFileManager.h
//  摄像
//
//  Created by 谢兴达 on 2017/4/10.
//  Copyright © 2017年 谢兴达. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StoreFileManager : NSObject
+ (StoreFileManager *)defaultManager;

/**
 删除指定path下的文件

 @param path 路径
 */
- (void)removeItemAtPath:(NSString *)path;

/**
 删除指定URL下的文件

 @param URL 本地url
 */
- (void)removeItemAtUrl:(NSURL *)URL;

@end
