//
//  Config.m
//  Conversation
//
//  Created by junpengwang on 2017/5/23.
//  Copyright © 2017年 wilddog. All rights reserved.
//

#import "Config.h"

@implementation Config
+ (instancetype)defaultConfig {
    static Config *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[Config alloc] init];
        _instance.videoConstraints = WDGVideoConstraints480p;
    });
    return _instance;
}
@end
