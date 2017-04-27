//
//  InviteViewController.m
//  Convasation
//
//  Created by junpengwang on 2017/4/26.
//  Copyright © 2017年 wilddog. All rights reserved.
//

#import "InviteViewController.h"
#import "PGSkinPrettifyEngine.h"
#import "RoomViewController.h"

@import WilddogVideo;
@import WilddogSync;
@import WilddogAuth;
@import WilddogCore;

@interface InviteViewController ()<WDGVideoClientDelegate> {
    PGSkinPrettifyEngine *_pPGSkinPrettifyEngine;
}

@property (nonatomic, strong) WDGSyncReference *wilddogSyncReference;
@property (nonatomic, strong) WDGAuth *wilddogAuth;
@property (nonatomic, strong) WDGVideoClient *wilddogVideoClient;

@property (nonatomic) __attribute__((NSObject)) CFMutableArrayRef sampleBufferList;
@property (strong, nonatomic) dispatch_queue_t mSkinQueue;
@property (nonatomic, strong) dispatch_semaphore_t frameRenderingSemaphore;
@property (nonatomic, strong) NSMutableArray<NSString *> *onLineUsers;
@property (nonatomic, strong) NSString *myUserID;

@end


#define DEMOKEY @"VkV3Nf+H1yOBI59QE4Uc8Pq/Lu0jXC9OmFKqVwGakeyerQOaROUJkZyR9zP4KvPJPinMUafrWqQN8KSNwEGZGi5WFT4jrBeLjZslLp0tUkCXC/wY8BSlQAA2pyq6q5Ovz2QG0Jm9rXCjfTn/5r8TaaWaRCuRZoTNyOZVaKZeH6I="

@implementation InviteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Not Login";
    
    self.onLineUsers = [NSMutableArray new];
    
    [self setupCamera360];
    
    [self setupWilddogSyncAndAuth];
    
    [self observeringOnlineUser];
    
    [self setupWilddogVideoClient];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - init

- (void)setupCamera360 {
    _pPGSkinPrettifyEngine = [[PGSkinPrettifyEngine alloc] init];
    
    [_pPGSkinPrettifyEngine InitEngineWithKey:DEMOKEY];
    
    _sampleBufferList = CFArrayCreateMutable(kCFAllocatorDefault, 0, & kCFTypeArrayCallBacks);//存储需要处理的数据
    _mSkinQueue = dispatch_queue_create("com.skin.configure", DISPATCH_QUEUE_SERIAL);
    
    _frameRenderingSemaphore = dispatch_semaphore_create(1);//通过信号量来保护数据
}

- (void)setupWilddogSyncAndAuth {
    [WDGApp configureWithOptions:[[WDGOptions alloc] initWithSyncURL:@"https://wildvideo.wilddogio.com/"]];
    self.wilddogSyncReference = [[[WDGSync sync] reference] child:@"wilddogVideo"];
    self.wilddogAuth = [WDGAuth auth];
}

- (void)setupWilddogVideoClient {
    
    [self.wilddogAuth signInAnonymouslyWithCompletion:^(WDGUser * _Nullable user, NSError * _Nullable error) {
        
        if (error) {
            [self.wilddogAuth signOut:nil];
        }
        if (!user) {
            NSLog(@"请在控制台为您的AppID开启匿名登录功能");
        }
        self.title = user.uid;
        self.myUserID = user.uid;
        [[[self.wilddogSyncReference.root child:@"users"] child:user.uid] setValue:@YES withCompletionBlock:^(NSError * _Nullable error, WDGSyncReference * _Nonnull ref) {
            [ref onDisconnectRemoveValue];
            self.wilddogVideoClient = [[WDGVideoClient alloc] initWithApp:[WDGApp defaultApp]];
            self.wilddogVideoClient.delegate = self;
        }];
    }];
}

- (void)observeringOnlineUser {
    
    __weak typeof(self) weakSelf = self;
    [[self.wilddogSyncReference.root child:@"users"] observeEventType:WDGDataEventTypeValue withBlock:^(WDGDataSnapshot * _Nonnull snapshot) {
        NSDictionary *dic = snapshot.value;
        NSMutableArray *users = [dic.allKeys mutableCopy];
        for (NSString *uid in users) {
            if ([uid isEqualToString:weakSelf.wilddogAuth.currentUser.uid]) {
                [users removeObject:uid];
                break;
            }
        }
        self.onLineUsers = users;
        [weakSelf.tableView reloadData];
    }];

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.onLineUsers.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    cell.textLabel.text = self.onLineUsers[indexPath.row];
    
    return cell;
}

#pragma mark - Table View Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self inviteUserWithUid:self.onLineUsers[indexPath.row] client:self.wilddogVideoClient];
}

#pragma mark - WDGVideoClient Dalegate
- (void)wilddogVideoClient:(WDGVideoClient *)videoClient didReceiveInvite:(WDGVideoIncomingInvite *)invite {
    [self processIncomingInvitation:invite];
}

- (void)wilddogVideoClient:(WDGVideoClient *)videoClient inviteDidCancel:(WDGVideoIncomingInvite *)invite {

}

#pragma mark - method
- (void)inviteUserWithUid:(NSString *)uid client:(WDGVideoClient *)client {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"邀请"
                                                                   message:[NSString stringWithFormat:@"正在邀请 %@ 进行视频通话",uid]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    WDGVideoLocalStreamOptions *option = [[WDGVideoLocalStreamOptions alloc] init];
    option.videoOption = WDGVideoConstraintsHigh;
    WDGVideoLocalStream *localStream = [[WDGVideoLocalStream alloc] initWithOptions:option];
    
    WDGVideoConnectOptions *connectOptions = [[WDGVideoConnectOptions alloc] initWithLocalStream:localStream];
    connectOptions.userData = @"abc";
    
    WDGVideoOutgoingInvite *outgoingInvitation = [self.wilddogVideoClient inviteToConversationWithID:uid options:connectOptions completion:^(WDGVideoConversation * _Nullable conversation, NSError * _Nullable error) {
        assert(error == nil);
        [self dismissViewControllerAnimated:YES
                                 completion:^{
                                     [self presentRoomWithConversation:conversation];
                                 }];
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消邀请" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [outgoingInvitation cancel];
    }]];
    
    [self presentViewController:alert animated:YES completion:NULL];
}

- (void)presentRoomWithConversation:(WDGVideoConversation *)conversation {
    UINavigationController *roomNavigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"RoomNavigationController"];
    RoomViewController *roomVC = roomNavigationController.viewControllers.firstObject;
    if (![roomVC isKindOfClass:[RoomViewController class]]) {
        return;
    }
    roomVC.wilddogVideoConversation = conversation;
    roomVC.syncReference = self.wilddogSyncReference;
    roomVC.wilddogVideoClient = self.wilddogVideoClient;
    [self presentViewController:roomNavigationController animated:YES completion:NULL];
}

- (void)processIncomingInvitation:(WDGVideoIncomingInvite *)invite {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:invite.fromParticipantID
                                                                   message:[NSString stringWithFormat:@"%@ 邀请你进行视频通话", invite.fromParticipantID]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"拒绝" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [invite reject];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"接受" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        WDGVideoLocalStreamOptions *option = [[WDGVideoLocalStreamOptions alloc] init];
        option.videoOption = WDGVideoConstraintsHigh;
        WDGVideoLocalStream *localStream = [[WDGVideoLocalStream alloc] initWithOptions:option];
        [invite acceptWithLocalStream:localStream completion:^(WDGVideoConversation * _Nullable conversation, NSError * _Nullable error) {
            assert(error == nil);
            [self presentRoomWithConversation:conversation];
        }];
    }]];
    
    [self presentViewController:alert animated:YES completion:NULL];

}
#pragma mark -
@end
