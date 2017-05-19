//
//  RoomViewController.m
//  Convasation
//
//  Created by junpengwang on 2017/4/26.
//  Copyright © 2017年 wilddog. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <WilddogVideo/WilddogVideo.h>

#import "RoomViewController.h"
#import "PGSkinPrettifyEngine.h"


@interface RoomViewController () <WDGVideoConversationDelegate,WDGVideoLocalStreamDelegate,WDGVideoParticipantDelegate,WDGVideoConversationStatsDelegate>

- (IBAction)dismiss:(id)sender;
@property (weak, nonatomic) IBOutlet UITextView *logView;
@property (weak, nonatomic) IBOutlet WDGVideoView *localVideoView;
@property (weak, nonatomic) IBOutlet WDGVideoView *remoteVideoView;

@property (nonatomic, strong) WDGVideoLocalStream *localStream;
@property (nonatomic, strong) WDGVideoOutgoingInvite *outgoingInvite;

// camera 360
@property (nonatomic, strong) PGSkinPrettifyEngine *pPGSkinPrettifyEngine;
@property (nonatomic) __attribute__((NSObject)) CFMutableArrayRef sampleBufferList;
@property (strong, nonatomic) dispatch_queue_t mSkinQueue;
@property (nonatomic, assign) BOOL m_bIsFirstFrame;

@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *fpsLabel;
@property (weak, nonatomic) IBOutlet UILabel *bitSentLabel;
@property (weak, nonatomic) IBOutlet UILabel *sendRateLabel;

@property (weak, nonatomic) IBOutlet UILabel *remoteSize;
@property (weak, nonatomic) IBOutlet UILabel *remotefps;
@property (weak, nonatomic) IBOutlet UILabel *bitRecieve;
@property (weak, nonatomic) IBOutlet UILabel *receiverate;


@end

#define DEMOKEY @"V3z027VFqM0gXahNjSOMgZNa00zfhcKkGDC32rRfP5029ibAJTV5G4989LSEZkE23LMBafvgXsJpd12NEoiBpoI0jDGUv/Dx1AMcjMuWXPs0xPWeNkXcFTQymERtdzac4Vv6yYsOKXH2KKvEN/UIafr3CLuUNXxUsP00ZtTZ6qgwpGpqStdj0CRR/RQQwfcuj6xMpT95mHV0nnVcSHP9Qa4SEIrIQBiLDFxWJ3J+29mHbD9aV4t0QF5URKwhJqdw/7kMBFT2ENtfSghwzEeCqDEZT9VEQM79MqDnLDRVvPXqLQSLOKg3IPpGZvhqCUXfdmIOzFAHM2weD6ca4YkUxh4P+jvaiNbg4ZcT9zpEsMmIL3KZdCPGw4YxQh2WM2X6u6KdeDMVh1NCJ3VTpk0PaAQsv6OcCYUQBVFefqR+1gMC1qCVhdxSctj1XnM2kleJMLykoJhwNnMqaakhKy6llu/jvo0TwCAEcc0du2bkb5vOLRdlQsrsfCZzAxfpRZ0eORiH0//AnT39QoLzQBcGIxlp1OBtNNOaezt3QzI/BPueNWMYL1ZdO2yPBT7Rd1sazozeh2XAX7FpH4JNqasJr7+66xpy8w5+pIXBe61f3NQHaKPU6UpmKIY/7/b6Rn87Afzy604yE4Ufq+97YNl61z33cqYnHoC8QrQZnmWMZYpSnBZ1q3/cveY6TmDWTn1qGTGGnp0sg55nRLL6trxN0G1RNqzzEWrv/uS7Eo/+wxhHFsRmbVT3SUPsYwU+VdaFxc/n7cma9qKjN/3KeQzx7wj+MIFHqMHjHAm74EgkaqbB3qYjMWKhC4RPrngajG0zyh8gGkypWEDtyQT1ERePOzupKxXpTm3Hz7HT59iE2InznKNyEDExEX+vt6a76kj+sN8NsuCWOH3yRtIFkOEAfelmQh3ainxT3C7LStopPiZ/6vUHc30u7VnnawKKJk7gg5j7cs8pL6aVERy9r9Of8Txqnb15eToHejiRkVHLQ+CGY/HVl46G5olwhCKcj9VlKOdu7xdF8uhJEoDexy6LcuSpmp3mcAri7cPVnDM73/qH3LPF/EQeW7ssf5MdeBd5+29u/aNnROqFQ3qYgOZ9+SnX1vLv7aoaWWvQUCAVA5wzd++4nFztwbY700mIKDsVQQolxcz9FS1FKtSzL6xeqn3MUYnImnWyl/J1E7gbOp1/BL3XMimHRzxJzwxL5roZJM5734yNoQmiKuEKO9EZI4/Zg38NherJLZOCQdbVi032/6xHNpEeYmwMmbLKi1PZDjxcq/cMmLjAllQzazwsHudmQGurnQeAsAqxYpp42WLgYH7ka0ditptiTrAXFkoQOyfShqGgFZgc/TV6RSTPHG26OVkh/ro5rkCuzbafN0cTOauDYLMPD2b1bTd/EhWT2kL6N36lxO6a2fTBuMj+mAH25FZOS7JgQLvhbdPu2f3tgqO5TUOruwUzkN59Mcfl18dhdnVCQG3gNEwK28MtIvIQabKldNgdZncDVOwSJpepruZZPNF6EtgUt/AO+76lYcjcXcDzcmmT3Ix7kno7akW1OTh1wkVmMJAUXtXjKsd0sagof9GTEoC1RSGyhEDJxP2v6W7CovJ2ypohV6KK9KgyCg0mapr+SMKoKepK7K/Y0idRCNiUj7Dan7pEnqCY53o5l5EYRalKm+bnGWmZo7AMbIgqc2SJH3Nx9aWg4XpmO/r/tQmJWayDE5lO9FhTqXlNfYXaeMvCY11j0jc6"

@implementation RoomViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    [self setupCamera360];

    return [super initWithCoder:aDecoder];
}

- (void)dealloc {
    NSLog(@"RoomViewController dealloc");
    
    [_pPGSkinPrettifyEngine DestroyEngine];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    self.remoteVideoView.contentMode = UIViewContentModeScaleAspectFill;
    self.localVideoView.contentMode = UIViewContentModeScaleAspectFill;
    [self setupStream];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSessionRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];

    // Do any additional setup after loading the view.
}

- (void)viewDidDisappear:(BOOL)animated {

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupCamera360 {
    _pPGSkinPrettifyEngine = [[PGSkinPrettifyEngine alloc] init];
    
    _m_bIsFirstFrame = YES;
    
    [_pPGSkinPrettifyEngine InitEngineWithKey:DEMOKEY];
    
    _sampleBufferList = CFArrayCreateMutable(kCFAllocatorDefault, 0, & kCFTypeArrayCallBacks);//存储需要处理的数据
    _mSkinQueue = dispatch_queue_create("com.skin.configure", DISPATCH_QUEUE_SERIAL);
    
    [self.pPGSkinPrettifyEngine SetSkinSoftenAlgorithm:PGSoftenAlgorithmContrast];
    
    /*--------------------增加滤镜----------------------*/
    
    [_pPGSkinPrettifyEngine SetColorFilterStrength:100];
    [_pPGSkinPrettifyEngine SetColorFilterByName:@"Deep"];
    
    /*---------------------------------增加贴纸---------------------------------*/
    
//    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
//    NSString *stickerPath = [bundlePath stringByAppendingPathComponent:@"/天使羽毛"];
//    
//    [_pPGSkinPrettifyEngine StickerEnable:YES];
//    [_pPGSkinPrettifyEngine SetStickerPackagePath:stickerPath];

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
        [_pPGSkinPrettifyEngine SetOutputOrientation:PGOrientationNormal];
        //        [_pPGSkinPrettifyEngine SetSkinPrettifyResultDelegate:self];
        [_pPGSkinPrettifyEngine SetSkinSoftenStrength:80];
        [_pPGSkinPrettifyEngine SetSkinColor:0.6 Whitening:0.5 Redden:0.6];
        
        self.m_bIsFirstFrame = NO;
    }
        
    //  对当前帧进行美肤
    
    [_pPGSkinPrettifyEngine SetInputFrameByCVImage:pixelBuffer];
    [_pPGSkinPrettifyEngine SetSkinColor:1 Whitening:1 Redden:1];
    [_pPGSkinPrettifyEngine RunEngine];
    [_pPGSkinPrettifyEngine PGOglViewPresent];
    
    [_pPGSkinPrettifyEngine GetSkinPrettifyResult:&pixelBuffer];
    OSType type = CVPixelBufferGetPixelFormatType(pixelBuffer);
    if (type != kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
        NSLog(@"error pixel type");
        return nil;
    }
    return pixelBuffer;

}
#pragma mark -

#pragma mark WDGVideoConversationStatsDelegate
- (void)conversation:(WDGVideoConversation *)conversation didUpdateLocalStreamStatsReport:(WDGVideoLocalStreamStatsReport *)report {
    dispatch_async(dispatch_get_main_queue(), ^{
        _sizeLabel.text = [NSString stringWithFormat:@"%lu*%lu",(unsigned long)report.width,report.height];
        _fpsLabel.text = [NSString stringWithFormat:@"fps:%lu",(unsigned long)report.FPS];
        _bitSentLabel.text = [NSString stringWithFormat:@"sent:%.2fMB ",report.bytesSent/1024/1024.f];
        _sendRateLabel.text = [NSString stringWithFormat:@"rate:%.2fKBS ",report.bitsSentRate/8.f];
        
//        NSMutableString *des = [NSMutableString stringWithString:@"LocalStream:"];
//        [des appendFormat:@"width*height:%lu*%lu ",(unsigned long)report.width,(unsigned long)report.height];
//        [des appendFormat:@"FPS:%lu ",(unsigned long)report.FPS];
//        [des appendFormat:@"sent:%2fMB ",report.bytesSent/8/1024/1024.f];
//        [des appendFormat:@"rate:%2fKBS ",report.bitsSentRate/8.f];
//        _logView.text = [_logView.text stringByAppendingString:des];
//        [_logView setContentOffset:CGPointMake(0,  (_logView.contentSize.height - _logView.frame.size.height))];
    });
}

- (void)conversation:(WDGVideoConversation *)conversation didUpdateRemoteStreamStatsReport:(WDGVideoRemoteStreamStatsReport *)report {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        _remoteSize.text = [NSString stringWithFormat:@"%lu*%lu",(unsigned long)report.width,report.height];
        _remotefps.text = [NSString stringWithFormat:@"fps:%lu",(unsigned long)report.FPS];
        _bitRecieve.text = [NSString stringWithFormat:@"recieved:%.2fMB ",report.bytesReceived/1024/1024.f];
        _receiverate.text = [NSString stringWithFormat:@"rate:%.2fKBS delay%lums",report.bitsReceivedRate/8.f,(unsigned long)report.delay];
        
//        NSMutableString *des = [NSMutableString stringWithString:@"RemoteStream:"];
//        [des appendFormat:@"width*height:%lu*%lu ",(unsigned long)report.width,(unsigned long)report.height];
//        [des appendFormat:@"FPS:%lu ",(unsigned long)report.FPS];
//        [des appendFormat:@"bytesReceived:%2fMB ",report.bytesReceived/8/1024/1024.f];
//        [des appendFormat:@"ReceivedRate:%2fKBS ",report.bitsReceivedRate/8.f];
//        [des appendFormat:@"Delay %lums ",(unsigned long)report.delay];
//        _logView.text = [_logView.text stringByAppendingString:des];
//        [_logView setContentOffset:CGPointMake(0,  (_logView.contentSize.height - _logView.frame.size.height))];
    });
}
#pragma mark -


- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    return NO;
}
- (IBAction)setting:(id)sender {
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
