//
//  Camera360Engine.h
//  Conversation
//
//  Created by junpengwang on 07/06/2017.
//  Copyright © 2017 wilddog. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

@interface Camera360Engine : NSObject

+ (instancetype)sharedInstance;

- (CVPixelBufferRef)proccessPixelBuffer:(CVPixelBufferRef)buffer;
@end
