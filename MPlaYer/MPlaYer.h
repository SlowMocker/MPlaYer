//
//  MPlaYer.h
//  MPlaYer
//
//  Created by wuwenhao on 2020/8/17.
//  Copyright © 2020 MOSI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MPlaYerStatus){
    MPlaYerStatusLOADING, // 资源加载中
    MPlaYerStatusPLAYING, // 播放中
    MPlaYerStatusPAUSE, // 暂停中
    MPlaYerStatusEND, // 播放结束
    MPlaYerStatusSTOP, // 停止
    MPlaYerStatusDISPOSAL, // 销毁（暂时没用）
};

@interface MPlaYer : NSObject

/// 是否只是抓取 PCM
@property (nonatomic , assign) BOOL isJustFetchPCM;
/// PCM 数据独立回调
@property (nonatomic , copy) void (^ __nullable pcmCallback)(AudioBuffer ioData);
/// 播放器状态回调
@property (nonatomic , copy) void (^ __nullable playerStatusCallback)(MPlaYerStatus status);
/// 播放器进度回调
@property (nonatomic , copy) void (^ __nullable playerProgressCallback)(float progress);

/// 播放
- (void) play:(NSURL *)url;
/// 恢复播放
- (void) resume;
/// 暂停
- (void) pause;
/// 停止
- (void) stop;
@end
NS_ASSUME_NONNULL_END
