//
//  Config.h
//  Conversation
//
//  Created by junpengwang on 2017/5/23.
//  Copyright © 2017年 wilddog. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WilddogVideo/WilddogVideo.h>

@interface Config : NSObject

+ (instancetype)defaultConfig;

@property (nonatomic, assign) WDGVideoConstraints videoConstraints;
@end
