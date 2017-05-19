//
//  RoomViewController.h
//  Convasation
//
//  Created by junpengwang on 2017/4/26.
//  Copyright © 2017年 wilddog. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WDGVideoConversation;
@class WDGSyncReference;
@class WDGVideoClient;

@interface RoomViewController : UIViewController

@property (nonatomic, strong) WDGVideoConversation *wilddogVideoConversation;
@property (nonatomic, strong) WDGSyncReference *syncReference;
@property (nonatomic, strong) WDGVideoClient *wilddogVideoClient;
@property (nonatomic, strong) NSString *uid;

@end
