### 运行工程
1.在控制台中进入工程目录执行 ：

```
pod install
open Convasation.xcworkspace -a xcode
```
2.下载 Camera360 美颜 SDK。Camera360 相关文档请参考：[品果视频美肤引擎](https://github.com/pinguo/PGSkinPrettifyEngine)
3.分别在两个手机上安装此项目，同时打开测试应用，在一端点击列表中的人员就可以邀请对方加入视频聊天。   
	  
### 需要配置参数
Demo 中不需要配置任何参数即可正常运行。如需使用自己帐号，请替换两个地方：

1. InviteViewController.m 第 61 行的野狗 AppID。账号注册请参考 [视频通话](https://docs.wilddog.com/video/iOS/quickstart/ios-conversation.html)
2. RoomViewController.m 第 45 行的 Camera360 的 DEMOKEY。（注意和 bundleID 相对应。)

### 接口介绍
视频流处理接口：创建本地视频流 `WDGVideoLocalStream` 时，设置视频流处理代理，将 pixelBuffer 处理完后返回给 WilddogVideo。

`WDGVideoLocalStream`


```
@property (nonatomic, weak) id<WDGVideoLocalStreamDelegate> delegate;

@protocol WDGVideoLocalStreamDelegate <NSObject>

@optional
- (CVPixelBufferRef)processPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
```

### 相关文档
- 野狗视频通话快速入门请参考：[快速入门](https://docs.wilddog.com/video/iOS/quickstart/ios-conversation.html)
- Camera360 相关文档请参考：[品果视频美肤引擎](https://github.com/pinguo/PGSkinPrettifyEngine)

### 已知问题
- 无
