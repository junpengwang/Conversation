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

#import <WilddogVideo/WilddogVideo.h>
#import <WilddogSync/WilddogSync.h>
#import <WilddogAuth/WilddogAuth.h>
#import <WilddogCore/WilddogCore.h>

@interface InviteViewController ()<WDGVideoClientDelegate> {
}

- (IBAction)setting:(id)sender;
@property (nonatomic, strong) WDGSyncReference *wilddogSyncReference;
@property (nonatomic, strong) WDGAuth *wilddogAuth;
@property (nonatomic, strong) WDGVideoClient *wilddogVideoClient;

@property (nonatomic, strong) NSMutableArray<NSString *> *onLineUsers;
@property (nonatomic, strong) NSString *myUserID;

@property (nonatomic, assign) WDGVideoConstraints videoConstraints;

@end



@implementation InviteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Not Login";
    self.videoConstraints = WDGVideoConstraints720p;
    self.onLineUsers = [NSMutableArray new];
    
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

- (void)setupWilddogSyncAndAuth {
    [WDGApp configureWithOptions:[[WDGOptions alloc] initWithSyncURL:@"https://wildvideo.wilddogio.com/"]];
    self.wilddogSyncReference = [[[WDGSync sync] reference] child:@"wilddogVideo"];
    self.wilddogAuth = [WDGAuth auth];
}

- (void)setupWilddogVideoClient {
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];

    __weak typeof(self) weakSelf = self;
    [[[[WDGSync sync] reference] child:@".info/connected"] observeEventType:WDGDataEventTypeValue withBlock:^(WDGDataSnapshot * _Nonnull snapshot) {
        if ([snapshot.value boolValue]) {
            if (weakSelf.myUserID) {
                WDGSyncReference *ref = [[weakSelf.wilddogSyncReference.root child:@"users"] child:weakSelf.myUserID];
                [ref setValue:@YES withCompletionBlock:^(NSError * _Nullable error, WDGSyncReference * _Nonnull ref) {
                    assert(error==nil);
                    [ref onDisconnectRemoveValueWithCompletionBlock:^(NSError * _Nullable error, WDGSyncReference * _Nonnull ref) {
                        assert(error == nil);
                    }];
                }];
            }
        }
    }];

    [self.wilddogAuth signOut:nil];

    [self.wilddogAuth signInAnonymouslyWithCompletion:^(WDGUser * _Nullable user, NSError * _Nullable error) {
        
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
    
    [self.wilddogAuth addAuthStateDidChangeListener:^(WDGAuth * _Nonnull auth, WDGUser * _Nullable user) {
        
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
        NSLog(@"users-----%@",users);
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
    option.videoOption = self.videoConstraints;
    WDGVideoLocalStream *localStream = [[WDGVideoLocalStream alloc] initWithOptions:option];
    
    WDGVideoConnectOptions *connectOptions = [[WDGVideoConnectOptions alloc] initWithLocalStream:localStream];
    connectOptions.userData = @"abc";
    
    WDGVideoOutgoingInvite *outgoingInvitation = [self.wilddogVideoClient inviteToConversationWithID:uid options:connectOptions completion:^(WDGVideoConversation * _Nullable conversation, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@",error);
        }
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
        option.videoOption = self.videoConstraints;
        WDGVideoLocalStream *localStream = [[WDGVideoLocalStream alloc] initWithOptions:option];
        NSLog(@"%@",localStream);
        [invite acceptWithLocalStream:localStream completion:^(WDGVideoConversation * _Nullable conversation, NSError * _Nullable error) {
            assert(error == nil);
            [self presentRoomWithConversation:conversation];
        }];
    }]];
    
    [self presentViewController:alert animated:YES completion:NULL];

}
#pragma mark -
- (IBAction)setting:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设置清晰度"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    
    [alert addAction:[UIAlertAction actionWithTitle:@"360p" style:(_videoConstraints == WDGVideoConstraints360p)? UIAlertActionStyleDestructive : 0 handler:^(UIAlertAction * _Nonnull action) {
        self.videoConstraints = WDGVideoConstraints360p;
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"480p" style:(_videoConstraints == WDGVideoConstraints480p)? UIAlertActionStyleDestructive : 0 handler:^(UIAlertAction * _Nonnull action) {
        self.videoConstraints = WDGVideoConstraints480p;

    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"720p" style:(_videoConstraints == WDGVideoConstraints720p)? UIAlertActionStyleDestructive : 0 handler:^(UIAlertAction * _Nonnull action) {
        self.videoConstraints = WDGVideoConstraints720p;
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"1080p" style:(_videoConstraints == WDGVideoConstraints1080p)? UIAlertActionStyleDestructive : 0 handler:^(UIAlertAction * _Nonnull action) {
        self.videoConstraints = WDGVideoConstraints1080p;
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        self.videoConstraints = WDGVideoConstraints1080p;
    }]];
    [self presentViewController:alert animated:YES completion:NULL];
}
@end
