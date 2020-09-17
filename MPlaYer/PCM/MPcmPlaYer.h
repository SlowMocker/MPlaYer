//
//  MPcmPlaYer.h
//  QPlayAutoDemo
//
//  Created by iSmicro on 2020/8/30.
//  Copyright © 2020 wuwenhao. All rights reserved.
//

// 潜在问题：
// 1. AudioQueue 播着播着就停了
// 缓冲区长期处于饥饿状态，AudioQueue 可能就用不了了。饥饿时间限定不定，短则几百毫秒，多则几秒
// 2. 锁屏导致的问题
// 锁屏（休眠）状态下，系统会降低 APP 唤醒次数以降低功耗，所以 aqBufferAvalidCallback 的回调也会有延迟。导致的结果是声音可能已经播了很久了回调才回来。


#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MPcmPlaYer;

#define kNotificationShouldFillAudioQueueBuffer @"kNotificationShouldFillAudioQueueBuffer"

// 1. kBufferCount * kBufferSize == kSubBufferCount * kSubBufferSize
// 2. kBufferSize 是 kSubBufferSize 的整数倍
// 生产者使用
#define kBufferCount 3
#define kBufferSize (1024*1000) // 1000K
// 消费者使用
#define kSubBufferCount 60
#define kSubBufferSize (1024*50) // 50K
// kBufferCount == 3 时。如果大于 3 则依次递推
#define kShouldFillDataCount0 20 // kSubBufferCount / (kBufferCount+0)
#define kShouldFillDataCount1 40 // kSubBufferCount / (kBufferCount+1)

@interface MPcmPlaYer : NSObject
/// 当前播放信息标识
/// 每次 prepare 都会重置
@property (nonatomic , copy , readonly) NSString *sourceIdentifier;
@property (nonatomic , assign , readonly) BOOL isRunning;
@property (nonatomic , assign , readonly) AudioStreamBasicDescription asbd;

/// 是否只是抓取 PCM
@property (nonatomic , assign) BOOL isJustFetchPCM;
/// PCM 数据独立回调
@property (nonatomic , copy) void (^pcmCallback)(AudioBuffer ioData);
/// 消耗数据长度回调，用于外部计算播放进度
@property (nonatomic , copy) void (^didComsumeDataLengthCallback)(int dataLength);

/// 所有的 queue buffer 全部为空
/// 返回 YES 表示播放结束
@property (nonatomic , copy) BOOL (^allBufferNullCallback)(void);
/// 预加载（play 之前必调）
- (void) prepareToPlay:(AudioStreamBasicDescription)asbd;
/// 播放
- (void) play;
/// 暂停
- (void) pause;
/// 恢复播放
- (void) resume;
/// 停止
- (void) stop;
/// 释放全局 C 变量
- (void) releaseGC;

/// 将 buffer 加入队列
- (OSStatus) enqueueAudioBuffer:(AudioBuffer)buffer;

@end

NS_ASSUME_NONNULL_END
