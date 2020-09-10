//
//  MPcmPlaYer.h
//  QPlayAutoDemo
//
//  Created by iSmicro on 2020/8/30.
//  Copyright © 2020 腾讯音乐. All rights reserved.
//

// 潜在问题：
// 1. AudioQueue 播着播着就停了
// 缓冲区长期处于饥饿状态，AudioQueue 可能就用不了了。饥饿时间限定不定，短则几百毫秒，多则几秒
// 2. 锁屏导致的问题
// 锁屏（休眠）状态下，系统会降低 APP 唤醒次数以降低功耗，所以 aqBufferAvalidCallback 的回调也会有延迟。导致的结果是声音可能已经播了很久了回调才回来。


#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "MPlaYer.h"

NS_ASSUME_NONNULL_BEGIN


#define kNotificationShouldFillAudioQueueBuffer @"kNotificationShouldFillAudioQueueBuffer"

@interface MPcmPlaYer : NSObject
/// 音频参数
/// 切换曲目时，需要重新赋值
/// asbd 被重新赋值后，AudioQueueInstance 会 flush 所有 buffer
@property (nonatomic , assign) AudioStreamBasicDescription asbd;

/// 是否只是抓取 PCM
@property (nonatomic , assign) BOOL isJustFetchPCM;
/// PCM 数据独立回调
@property (nonatomic , copy) void (^pcmCallback)(AudioBuffer ioData);
/// 播放器状态回调
@property (nonatomic , copy) void (^playerStatusCallback)(MPlaYerStatus status);
/// 预加载
- (void) prepareToPlay;
/// 播放
- (void) play;
/// 暂停
- (void) pause;
/// 恢复播放
- (void) resume;
/// 停止
- (void) stop;

/// 将 buffer 加入队列
- (OSStatus) enqueueAudioBuffer:(AudioBuffer)buffer;

@end

NS_ASSUME_NONNULL_END
