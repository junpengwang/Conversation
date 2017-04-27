//
//  RoomViewController.m
//  Convasation
//
//  Created by junpengwang on 2017/4/26.
//  Copyright © 2017年 wilddog. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "RoomViewController.h"
#import "PGSkinPrettifyEngine.h"

@import WilddogVideo;

@interface RoomViewController () <WDGVideoConversationDelegate,WDGVideoLocalStreamDelegate,WDGVideoParticipantDelegate>

- (IBAction)dismiss:(id)sender;
@property (weak, nonatomic) IBOutlet WDGVideoView *localVideoView;
@property (weak, nonatomic) IBOutlet WDGVideoView *remoteVideoView;

@property (nonatomic, weak) WDGVideoLocalStream *localStream;

// camera 360
@property (nonatomic, strong) PGSkinPrettifyEngine *pPGSkinPrettifyEngine;
@property (nonatomic) __attribute__((NSObject)) CFMutableArrayRef sampleBufferList;
@property (strong, nonatomic) dispatch_queue_t mSkinQueue;
@property (nonatomic, strong) dispatch_semaphore_t frameRenderingSemaphore;
@property (nonatomic, assign) BOOL m_bIsFirstFrame;

@end

#define DEMOKEY @"VkV3Nf+H1yOBI59QE4Uc8Pq/Lu0jXC9OmFKqVwGakeyerQOaROUJkZyR9zP4KvPJPinMUafrWqQN8KSNwEGZGi5WFT4jrBeLjZslLp0tUkCXC/wY8BSlQAA2pyq6q5Ovz2QG0Jm9rXCjfTn/5r8TaaWaRCuRZoTNyOZVaKZeH6I="

@implementation RoomViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    _pPGSkinPrettifyEngine = [[PGSkinPrettifyEngine alloc] init];
    
    _m_bIsFirstFrame = YES;
    
    [_pPGSkinPrettifyEngine InitEngineWithKey:DEMOKEY];
    
    _sampleBufferList = CFArrayCreateMutable(kCFAllocatorDefault, 0, & kCFTypeArrayCallBacks);//存储需要处理的数据
    _mSkinQueue = dispatch_queue_create("com.skin.configure", DISPATCH_QUEUE_SERIAL);
    
    _frameRenderingSemaphore = dispatch_semaphore_create(1);//通过信号量来保护数据
    

    return [super initWithCoder:aDecoder];
}

- (void)dealloc {
    [self.localStream close];
    self.localStream = nil;
    [_pPGSkinPrettifyEngine DestroyEngine];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
}

- (void)viewDidDisappear:(BOOL)animated {

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setWilddogVideoConversation:(WDGVideoConversation *)wilddogVideoConversation {
    // Note: Force storyboard load view.
    [self loadViewIfNeeded];
    self.localStream = wilddogVideoConversation.localParticipant.stream;
    _wilddogVideoConversation = wilddogVideoConversation;
    wilddogVideoConversation.delegate = self;
    self.localStream.delegate = self;
    [self.localStream attach:self.localVideoView];
    WDGVideoRemoteStream *remoteStream = wilddogVideoConversation.participant.stream;
    if (remoteStream) {
        [remoteStream attach:_remoteVideoView];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark WDGVideoConversationDelegate
- (void)conversationDidConnected:(WDGVideoConversation *)conversation {
    
}


- (void)conversation:(WDGVideoConversation *)conversation didFailedToConnectWithError:(NSError *)error {
    
}

/**
 `WDGVideoConversation` 通过调用该方法通知代理当前视频通话已断开连接。
 
 @param conversation 调用该方法的 `WDGVideoConversation` 实例。
 @param error 错误信息，描述连接断开的原因。本地主动断开连接时为 nil。
 */
- (void)conversation:(WDGVideoConversation *)conversation didDisconnectWithError:(NSError *_Nullable)error {
    
}

/**
 `WDGVideoConversation` 通过调用该方法通知代理当前视频通话有新的参与者加入。
 
 @param conversation 调用该方法的 `WDGVideoConversation` 实例。
 @param participant  代表新的参与者的 `WDGVideoParticipant` 实例。
 */
- (void)conversation:(WDGVideoConversation *)conversation didConnectParticipant:(WDGVideoParticipant *)participant {
    participant.delegate = self;
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
    
    if (!_pPGSkinPrettifyEngine) {
        return pixelBuffer;
    }
    CGSize size = CVImageBufferGetDisplaySize(pixelBuffer);
    
    // 在第一帧视频到来时，初始化美肤引擎，指定需要的输出大小和输出委托
    if (self.m_bIsFirstFrame)
    {
        PGOrientation orientForAdjustInput = PGOrientationNormal;
        CGSize sizeForAdjustInput = CGSizeMake(size.width, size.height);
        
        [_pPGSkinPrettifyEngine SetSizeForAdjustInput:sizeForAdjustInput];
        [_pPGSkinPrettifyEngine SetOrientForAdjustInput:orientForAdjustInput];
        [_pPGSkinPrettifyEngine SetOutputFormat:PGPixelFormatYUV420];
        [_pPGSkinPrettifyEngine SetOutputOrientation:PGOrientationFlipped];
        //        [_pPGSkinPrettifyEngine SetSkinPrettifyResultDelegate:self];
        [_pPGSkinPrettifyEngine SetSkinSoftenStrength:80];
        [_pPGSkinPrettifyEngine SetSkinColor:0.6 Whitening:0.5 Redden:0.6];
        
        self.m_bIsFirstFrame = NO;
    }
    _frameRenderingSemaphore = dispatch_semaphore_create(1);
    dispatch_semaphore_wait(_frameRenderingSemaphore, DISPATCH_TIME_FOREVER);
    CFArrayAppendValue(_sampleBufferList, pixelBuffer);
    dispatch_semaphore_signal(_frameRenderingSemaphore);
    
    __weak __typeof(self)weakSelf = self;
    
    
    NSDate *date = [NSDate date];
    //  对当前帧进行美肤
    
    [_pPGSkinPrettifyEngine SetInputFrameByCVImage:pixelBuffer];
    [_pPGSkinPrettifyEngine SetSkinColor:1 Whitening:1 Redden:1];
    [_pPGSkinPrettifyEngine RunEngine];
    [_pPGSkinPrettifyEngine PGOglViewPresent];
    
    [_pPGSkinPrettifyEngine GetSkinPrettifyResult:&pixelBuffer];
    
    NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:date];
    NSLog(@"接口耗时%f", time*1000);
    
    dispatch_semaphore_wait(weakSelf.frameRenderingSemaphore, DISPATCH_TIME_FOREVER);
    CFArrayRemoveValueAtIndex(weakSelf.sampleBufferList, 0);
    dispatch_semaphore_signal(weakSelf.frameRenderingSemaphore);
    OSType type = CVPixelBufferGetPixelFormatType(pixelBuffer);
    if (type != kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
        NSLog(@"error pixel type");
        return nil;
    }
    return pixelBuffer;

}
#pragma mark -
@end
