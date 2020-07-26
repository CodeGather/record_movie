//
//  StoreFileManager.m
//  摄像
//
//  Created by 谢兴达 on 2017/4/10.
//  Copyright © 2017年 谢兴达. All rights reserved.
//

#import "StoreFileManager.h"

@implementation StoreFileManager

+ (StoreFileManager *)defaultManager {
    static StoreFileManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!manager) {
            manager = [[StoreFileManager alloc]init];
        }
    });
    return manager;
}

- (void)removeItemAtPath:(NSString *)path {
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
}

- (void)removeItemAtUrl:(NSURL *)URL {
    if ([[NSFileManager defaultManager] fileExistsAtPath:[URL path]]) {
        [[NSFileManager defaultManager] removeItemAtURL:URL error:nil];
    }
}
@end
