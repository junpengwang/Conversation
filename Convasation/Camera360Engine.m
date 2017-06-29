//
//  Camera360Engine.m
//  Conversation
//
//  Created by junpengwang on 07/06/2017.
//  Copyright © 2017 wilddog. All rights reserved.
//

#import "Camera360Engine.h"
#import "PGSkinPrettifyEngine.h"

#define DEMOKEY @"V3z027VFqM0gXahNjSOMgZNa00zfhcKkGDC32rRfP5029ibAJTV5G4989LSEZkE23LMBafvgXsJpd12NEoiBpoI0jDGUv/Dx1AMcjMuWXPs0xPWeNkXcFTQymERtdzac4Vv6yYsOKXH2KKvEN/UIafr3CLuUNXxUsP00ZtTZ6qgwpGpqStdj0CRR/RQQwfcuj6xMpT95mHV0nnVcSHP9Qa4SEIrIQBiLDFxWJ3J+29mHbD9aV4t0QF5URKwhJqdw/7kMBFT2ENtfSghwzEeCqDEZT9VEQM79MqDnLDRVvPXqLQSLOKg3IPpGZvhqCUXfdmIOzFAHM2weD6ca4YkUxh4P+jvaiNbg4ZcT9zpEsMmIL3KZdCPGw4YxQh2WM2X6u6KdeDMVh1NCJ3VTpk0PaAQsv6OcCYUQBVFefqR+1gMC1qCVhdxSctj1XnM2kleJMLykoJhwNnMqaakhKy6llu/jvo0TwCAEcc0du2bkb5vOLRdlQsrsfCZzAxfpRZ0eORiH0//AnT39QoLzQBcGIxlp1OBtNNOaezt3QzI/BPueNWMYL1ZdO2yPBT7Rd1sazozeh2XAX7FpH4JNqasJr7+66xpy8w5+pIXBe61f3NQHaKPU6UpmKIY/7/b6Rn87Afzy604yE4Ufq+97YNl61z33cqYnHoC8QrQZnmWMZYpSnBZ1q3/cveY6TmDWTn1qGTGGnp0sg55nRLL6trxN0G1RNqzzEWrv/uS7Eo/+wxhHFsRmbVT3SUPsYwU+VdaFxc/n7cma9qKjN/3KeQzx7wj+MIFHqMHjHAm74EgkaqbB3qYjMWKhC4RPrngajG0zyh8gGkypWEDtyQT1ERePOzupKxXpTm3Hz7HT59iE2InznKNyEDExEX+vt6a76kj+sN8NsuCWOH3yRtIFkOEAfelmQh3ainxT3C7LStopPiZ/6vUHc30u7VnnawKKJk7gg5j7cs8pL6aVERy9r9Of8Txqnb15eToHejiRkVHLQ+CGY/HVl46G5olwhCKcj9VlKOdu7xdF8uhJEoDexy6LcuSpmp3mcAri7cPVnDM73/qH3LPF/EQeW7ssf5MdeBd5+29u/aNnROqFQ3qYgOZ9+SnX1vLv7aoaWWvQUCAVA5wzd++4nFztwbY700mIKDsVQQolxcz9FS1FKtSzL6xeqn3MUYnImnWyl/J1E7gbOp1/BL3XMimHRzxJzwxL5roZJM5734yNoQmiKuEKO9EZI4/Zg38NherJLZOCQdbVi032/6xHNpEeYmwMmbLKi1PZDjxcq/cMmLjAllQzazwsHudmQGurnQeAsAqxYpp42WLgYH7ka0ditptiTrAXFkoQOyfShqGgFZgc/TV6RSTPHG26OVkh/ro5rkCuzbafN0cTOauDYLMPD2b1bTd/EhWT2kL6N36lxO6a2fTBuMj+mAH25FZOS7JgQLvhbdPu2f3tgqO5TUOruwUzkN59Mcfl18dhdnVCQG3gNEwK28MtIvIQabKldNgdZncDVOwSJpepruZZPNF6EtgUt/AO+76lYcjcXcDzcmmT3Ix7kno7akW1OTh1wkVmMJAUXtXjKsd0sagof9GTEoC1RSGyhEDJxP2v6W7CovJ2ypohV6KK9KgyCg0mapr+SMKoKepK7K/Y0idRCNiUj7Dan7pEnqCY53o5l5EYRalKm+bnGWmZo7AMbIgqc2SJH3Nx9aWg4XpmO/r/tQmJWayDE5lO9FhTqXlNfYXaeMvCY11j0jc6"

@interface Camera360Engine () {
    BOOL _bIsFirstFrame;
}

// camera 360
@property (nonatomic, strong) PGSkinPrettifyEngine *pPGSkinPrettifyEngine;

@end

@implementation Camera360Engine

+ (instancetype)sharedInstance {
    static Camera360Engine *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[Camera360Engine alloc] init];
        [_instance setupCamera360];
    });
    return _instance;
}

- (CVPixelBufferRef)proccessPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    if (!_pPGSkinPrettifyEngine) {
        return pixelBuffer;
    }
    _bIsFirstFrame = YES;
    CGSize size = CVImageBufferGetDisplaySize(pixelBuffer);
    PGOrientation orientation = PGOrientationNormal;
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationPortrait:
            orientation = PGOrientationNormal;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            orientation = PGOrientationRightRotate180;
            break;
        case UIDeviceOrientationLandscapeLeft:
//            orientation = PGOrientationRightRotate90;
            break;
        case UIDeviceOrientationLandscapeRight:
//            orientation = PGOrientationRightRotate270;
            break;
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationUnknown:
            return pixelBuffer;
            // Ignore.
    }
    
    // 在第一帧视频到来时，初始化美肤引擎，指定需要的输出大小和输出委托
    if (_bIsFirstFrame)
    {
        PGOrientation orientForAdjustInput = PGOrientationNormal;
        CGSize sizeForAdjustInput = CGSizeMake(size.width, size.height);
        
        [_pPGSkinPrettifyEngine SetSizeForAdjustInput:sizeForAdjustInput];
        [_pPGSkinPrettifyEngine SetOrientForAdjustInput:orientForAdjustInput];
        [_pPGSkinPrettifyEngine SetOutputFormat:PGPixelFormatYUV420];
        //        [_pPGSkinPrettifyEngine SetSkinPrettifyResultDelegate:self];
        [_pPGSkinPrettifyEngine SetSkinSoftenStrength:80];
        [_pPGSkinPrettifyEngine SetSkinColor:0.6 Whitening:0.5 Redden:0.3];
        
        _bIsFirstFrame = NO;
    }
    
    //  对当前帧进行美肤
    [_pPGSkinPrettifyEngine SetOutputOrientation:orientation];
    
    [_pPGSkinPrettifyEngine SetInputFrameByCVImage:pixelBuffer];
    [_pPGSkinPrettifyEngine SetSkinColor:0.6 Whitening:0.5 Redden:0.3];
    [_pPGSkinPrettifyEngine RunEngine];
//        [_pPGSkinPrettifyEngine PGOglViewPresent];
    
    [_pPGSkinPrettifyEngine GetSkinPrettifyResult:&pixelBuffer];
    OSType type = CVPixelBufferGetPixelFormatType(pixelBuffer);
    if (type != kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
        NSLog(@"error pixel type");
        return nil;
    }
    return pixelBuffer;
}

- (void)setupCamera360 {
    _pPGSkinPrettifyEngine = [[PGSkinPrettifyEngine alloc] init];
        
    [_pPGSkinPrettifyEngine InitEngineWithKey:DEMOKEY];
    
    [self.pPGSkinPrettifyEngine SetSkinSoftenAlgorithm:PGSoftenAlgorithmContrast];
    
    /*--------------------增加滤镜----------------------*/
    
    //    [_pPGSkinPrettifyEngine SetColorFilterStrength:100];
    //    [_pPGSkinPrettifyEngine SetColorFilterByName:@"Deep"];
    
    /*---------------------------------增加贴纸---------------------------------*/
    
    //    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    //    NSString *stickerPath = [bundlePath stringByAppendingPathComponent:@"/天使羽毛"];
    //
    //    [_pPGSkinPrettifyEngine StickerEnable:YES];
    //    [_pPGSkinPrettifyEngine SetStickerPackagePath:stickerPath];
    
}



@end
