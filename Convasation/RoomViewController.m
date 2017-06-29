//
//  RoomViewController.m
//  Conversation
//
//  Created by junpengwang on 2017/4/26.
//  Copyright © 2017年 wilddog. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <WilddogVideo/WilddogVideo.h>

#import "RoomViewController.h"

#import "Config.h"
#import "Camera360Engine.h"

@interface RoomViewController () <WDGVideoConversationDelegate,WDGVideoLocalStreamDelegate,WDGVideoParticipantDelegate,WDGVideoConversationStatsDelegate>

- (IBAction)dismiss:(id)sender;
@property (weak, nonatomic) IBOutlet UITextView *logView;
@property (weak, nonatomic) IBOutlet WDGBeautyVideoView *localVideoView;
@property (weak, nonatomic) IBOutlet WDGBeautyVideoView *remoteVideoView;

@property (nonatomic, strong) WDGVideoLocalStream *localStream;
@property (nonatomic, strong) WDGVideoOutgoingInvite *outgoingInvite;

@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *fpsLabel;
@property (weak, nonatomic) IBOutlet UILabel *bitSentLabel;
@property (weak, nonatomic) IBOutlet UILabel *sendRateLabel;

@property (weak, nonatomic) IBOutlet UILabel *remoteSize;
@property (weak, nonatomic) IBOutlet UILabel *remotefps;
@property (weak, nonatomic) IBOutlet UILabel *bitRecieve;
@property (weak, nonatomic) IBOutlet UILabel *receiverate;

@property (weak, nonatomic) IBOutlet UIImageView *captureView;

@end


@implementation RoomViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    [Camera360Engine sharedInstance];

    return [super initWithCoder:aDecoder];
}

- (void)dealloc {
    NSLog(@"RoomViewController dealloc");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    self.remoteVideoView.contentMode = UIViewContentModeScaleAspectFill;
    self.localVideoView.contentMode = UIViewContentModeScaleAspectFill;
    self.remoteVideoView.layer.transform = CATransform3DMakeRotation(M_PI, 0, 1, 0);
    self.localVideoView.layer.transform = CATransform3DMakeRotation(M_PI, 0, 1, 0);
    [self setupStream];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSessionRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchView:)];
    [self.localVideoView addGestureRecognizer:tap];
    // Do any additional setup after loading the view.
    
}

- (void)switchView:(id)sender
{
    CGRect frame = self.localVideoView.frame;
    self.localVideoView.frame = self.remoteVideoView.frame;
    self.remoteVideoView.frame = frame;
    if(_localVideoView.frame.origin.x > 0) {
        [self.view bringSubviewToFront:self.localVideoView];
    } else {
        [self.view bringSubviewToFront:self.remoteVideoView];
    }
}


- (void)viewDidDisappear:(BOOL)animated {

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didSessionRouteChange:(NSNotification *)notification
{
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonCategoryChange: {
            // Set speaker as default route
            NSError* error;
            [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
        }
            break;
            
        default:
            break;
    }
}

- (void)setupStream
{
    __weak typeof(self) weakSelf = self;
    if (self.uid) {
        WDGVideoLocalStreamOptions *option = [[WDGVideoLocalStreamOptions alloc] init];
        option.videoOption = [Config defaultConfig].videoConstraints;
        WDGVideoLocalStream *localStream = [[WDGVideoLocalStream alloc] initWithOptions:option];
        WDGVideoConnectOptions *connectOptions = [[WDGVideoConnectOptions alloc] initWithLocalStream:localStream];
        connectOptions.userData = @"abc";
        self.outgoingInvite = [self.wilddogVideoClient inviteToConversationWithID:self.uid options:connectOptions completion:^(WDGVideoConversation * _Nullable conversation, NSError * _Nullable error) {
            if (error) {
                NSLog(@"%@",error);
                [weakSelf dismissViewControllerAnimated:YES completion:NULL];
                return ;
            }
            weakSelf.wilddogVideoConversation = conversation;
            weakSelf.wilddogVideoConversation.statsDelegate = weakSelf;
        }];
        self.localStream = localStream;
        self.localStream.delegate = self;

    } else {
        self.localStream = self.wilddogVideoConversation.localParticipant.stream;
        self.localStream.delegate = self;
        self.wilddogVideoConversation.delegate = self;
        self.wilddogVideoConversation.statsDelegate = self;
    }
    [self.localStream attach:self.localVideoView];
}


- (IBAction)dismiss:(id)sender {
    
    [self.outgoingInvite cancel];
    [self.wilddogVideoConversation disconnect];
    self.wilddogVideoConversation = nil;
    [self.localStream close];
    self.localStream = nil;
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)setWilddogVideoConversation:(WDGVideoConversation *)wilddogVideoConversation {
    _wilddogVideoConversation = wilddogVideoConversation;
    _wilddogVideoConversation.delegate = self;
    NSLog(@"invoke set conversation Delegate: %@",[NSDate date]);

}

#pragma mark WDGVideoConversationDelegate
/**
 `WDGVideoConversation` 通过调用该方法通知代理当前视频通话有新的参与者加入。
 
 @param conversation 调用该方法的 `WDGVideoConversation` 实例。
 @param participant  代表新的参与者的 `WDGVideoParticipant` 实例。
 */
- (void)conversation:(WDGVideoConversation *)conversation didConnectParticipant:(WDGVideoParticipant *)participant {
    NSLog(@"did connect participant");
    NSLog(@"invoke didConnectParticipant: %@",[NSDate date]);
    participant.delegate = self;
}

- (void)conversation:(WDGVideoConversation *)conversation didDisconnectWithError:(NSError *_Nullable)error {
    NSLog(@"conversation disconnect");
}

/**
 `WDGVideoConversation` 通过调用该方法通知代理当前视频通话某个参与者断开了连接。
 
 @param conversation 调用该方法的 `WDGVideoConversation` 实例。
 @param participant  代表已断开连接的参与者的 `WDGVideoParticipant` 实例。
 */
- (void)conversation:(WDGVideoConversation *)conversation didDisconnectParticipant:(WDGVideoParticipant *)participant {
    [participant.stream detach:self.remoteVideoView];
    [self dismissViewControllerAnimated:YES completion:^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"所有通话对象已经断开连接" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleCancel handler:NULL]];
        [self.presentingViewController presentViewController:alert animated:YES completion:NULL];
    }];
}

#pragma mark - WDGVideoParticipantDelegate

/**
 `WDGVideoParticipant` 通过该方法通知代理收到参与者发布的媒体流。
 
 @param participant `WDGVideoParticipant` 对象，代表当前参与者。
 @param stream `WDGVideoRemoteStream` 对象，代表收到的媒体流。
 */
- (void)participant:(WDGVideoParticipant *)participant didAddStream:(WDGVideoRemoteStream *)stream {
    NSLog(@"didAddStream attach remote video View ");
    [stream attach:_remoteVideoView];
}

/**
 `WDGVideoParticipant` 通过该方法通知代理未能收到参与者发布的媒体流。
 
 @param participant `WDGVideoParticipant` 对象，代表当前参与者。
 @param error 错误信息，描述连接失败的原因。
 */
- (void)participant:(WDGVideoParticipant *)participant didFailedToConnectWithError:(NSError *)error {
    
}


/**
 `WDGVideoParticipant` 通过该方法通知代理参与者的媒体流中断。
 
 @param participant `WDGVideoParticipant` 对象，代表当前参与者。
 @param error 错误信息，描述媒体流中断的原因。
 */
- (void)participant:(WDGVideoParticipant *)participant didDisconnectWithError:(NSError *_Nullable)error {
    [participant.stream detach:self.remoteVideoView];
}
#pragma mark - WDGVideoLocalStreamDelegate
- (CVPixelBufferRef)processPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    return [[Camera360Engine sharedInstance] proccessPixelBuffer:pixelBuffer];
}
#pragma mark -

#pragma mark WDGVideoConversationStatsDelegate
- (void)conversation:(WDGVideoConversation *)conversation didUpdateLocalStreamStatsReport:(WDGVideoLocalStreamStatsReport *)report {
    dispatch_async(dispatch_get_main_queue(), ^{
        _sizeLabel.text = [NSString stringWithFormat:@"%lu*%lu",(unsigned long)report.width,(unsigned long)report.height];
        _fpsLabel.text = [NSString stringWithFormat:@"fps:%lu",(unsigned long)report.FPS];
        _bitSentLabel.text = [NSString stringWithFormat:@"sent:%.2fMB ",report.bytesSent/1024/1024.f];
        _sendRateLabel.text = [NSString stringWithFormat:@"rate:%.2fKBS ",report.bitsSentRate/8.f];
    });
}

- (void)conversation:(WDGVideoConversation *)conversation didUpdateRemoteStreamStatsReport:(WDGVideoRemoteStreamStatsReport *)report {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        _remoteSize.text = [NSString stringWithFormat:@"%lu*%lu",(unsigned long)report.width,(unsigned long)report.height];
        _remotefps.text = [NSString stringWithFormat:@"fps:%lu",(unsigned long)report.FPS];
        _bitRecieve.text = [NSString stringWithFormat:@"recieved:%.2fMB ",report.bytesReceived/1024/1024.f];
        _receiverate.text = [NSString stringWithFormat:@"rate:%.2fKBS delay%lums",report.bitsReceivedRate/8.f,(unsigned long)report.delay];
        
    });
}
#pragma mark -


- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    return NO;
}

- (IBAction)setting:(id)sender {
//    [self.wilddogVideoConversation startVideoRecording:[NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/record_%@.mp4",[NSDate date]]]];
//    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设置清晰度"
//                                                                   message:nil
//                                                            preferredStyle:UIAlertControllerStyleActionSheet];
//    
//    [alert addAction:[UIAlertAction actionWithTitle:@"360p" style:0 handler:^(UIAlertAction * _Nonnull action) {
//        [self.localStream adaptOutputFormatToWidth:480 height:360 fps:1];
//    }]];
//    [alert addAction:[UIAlertAction actionWithTitle:@"480p" style:0 handler:^(UIAlertAction * _Nonnull action) {
//        [self.localStream adaptOutputFormatToWidth:640 height:480 fps:15];
//    }]];
//    [alert addAction:[UIAlertAction actionWithTitle:@"720p" style:0 handler:^(UIAlertAction * _Nonnull action) {
//        [self.localStream adaptOutputFormatToWidth:1280 height:720 fps:15];
//    }]];
//    [alert addAction:[UIAlertAction actionWithTitle:@"1080p" style:0 handler:^(UIAlertAction * _Nonnull action) {
//        [self.localStream adaptOutputFormatToWidth:1280 height:720 fps:15];
//    }]];
//    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
//        [self.localStream adaptOutputFormatToWidth:480 height:360 fps:15];
//    }]];
//    [self presentViewController:alert animated:YES completion:NULL];
}
@end
