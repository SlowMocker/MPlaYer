//
//  MPcmPlaYer.m
//  QPlayAutoDemo
//
//  Created by wuwenhao on 2020/8/30.
//  Copyright © 2020 MOSI. All rights reserved.
//

#import "MPcmPlaYer.h"

MPcmPlaYer *cPcmPlaYer = nil;

@interface MPcmPlaYer()
/// asbd
@property (nonatomic , assign) AudioStreamBasicDescription asbd;
/// 同步锁
@property (nonatomic , strong) NSLock *syncLock0;
@property (nonatomic , strong) NSLock *syncLock1;
/// 播放文件标识
@property (nonatomic , copy) NSString *sourceIdentifier;

@property (nonatomic , assign) BOOL isRunning;
@end

@implementation MPcmPlaYer
{
    /// AudioQueue 实例
    AudioQueueRef _aqInstance;
    /// buffers
    AudioQueueBufferRef _aqBuffers[kSubBufferCount];
    
    BOOL _forbidCallback;
    
    /// 已经填充过了一个大 buffer
    BOOL _didCacheOneBigBuffer;
    BOOL _playFlag;
}

- (id) init {
    self = [super init];
    if (self) {
        self.asbd = [self defaultAsbd];
        self.syncLock0 = [[NSLock alloc]init];
        self.syncLock1 = [[NSLock alloc]init];
        
        cPcmPlaYer = self;
        
        _forbidCallback = NO;
        _didCacheOneBigBuffer = NO;
        _playFlag = NO;
    }
    return self;
}

/// AudioQueueBuffer 读取为空回调
/// @param inUserData 用户数据
/// @param inAQ buffer 所属 AudioQueue
/// @param inBuffer 数据被读取完毕的 AudioQueueBuffer
void aqBufferDidReadCallback(void * __nullable inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
    [cPcmPlaYer.syncLock1 lock];
    
    // progress 回调
    if (cPcmPlaYer.didComsumeDataLengthCallback) {
        cPcmPlaYer.didComsumeDataLengthCallback(inBuffer->mAudioDataByteSize);
    }
    
    // buffer 数据不用重置，后续会被覆盖，只会读取被覆盖部分
//    memset(inBuffer->mAudioData, 0, kBufferSize);
    // buffer 有效数据标识重置
    inBuffer->mAudioDataByteSize = 0;
    
    if (cPcmPlaYer) {
        
        if (cPcmPlaYer.allBufferNullCallback && [cPcmPlaYer buffersNULL]) {
            // 最后一次回调的时候，在外部将 cPcmPlaYer 释放了
            if (cPcmPlaYer.allBufferNullCallback()) {
                [cPcmPlaYer.syncLock1 unlock];
                return;
            }
        }
        
        if (cPcmPlaYer->_forbidCallback) {
            [cPcmPlaYer.syncLock1 unlock];
            return;
        }
        
        if ([cPcmPlaYer shouldFillNewData]) {
            NSNotification *noti = [NSNotification notificationWithName:kNotificationShouldFillAudioQueueBuffer
                                                                 object:nil
                                                               userInfo:@{@"sourceId": cPcmPlaYer.sourceIdentifier}];
            [[NSNotificationCenter defaultCenter] postNotification:noti];
        }
    }
    [cPcmPlaYer.syncLock1 unlock];
}

void aqPropertyListenerCallback(void * __nullable inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID) {
    MPcmPlaYer *instance = (__bridge MPcmPlaYer *)inUserData;
    UInt32 isRunning = 0;
    UInt32 size = sizeof(isRunning);

    if (instance == NULL) return;
    // 停止可能需要调用 stop 触发
    OSStatus err = AudioQueueGetProperty(inAQ, kAudioQueueProperty_IsRunning, &isRunning, &size);
    if (!err && isRunning == 1) {
        NSLog(@"PCM player running: YES");
        cPcmPlaYer.isRunning = YES;
    }
    else {
        NSLog(@"PCM player running: NO");
        cPcmPlaYer.isRunning = NO;
    }
}

- (void) dealloc {
    [self dispose];
    NSLog(@"\n*\n\n\nMPcmPlaYer dealloc!!! Happiness Maybe!!!\n\n\n*");
}

#pragma mark - public methods
- (void) prepareToPlay:(AudioStreamBasicDescription)asbd {
    
    _forbidCallback = NO;
    _playFlag = NO;
    _didCacheOneBigBuffer = NO;
    
    if (asbd.mSampleRate > 0 && asbd.mFormatID == kAudioFormatLinearPCM) {
        self.asbd = asbd;
    }
    
    // 1. 重置 queue
    if (_aqInstance) {
        [self stop];
        _aqInstance = NULL;
    }
    [self initAudioQueueAndBuffers];

    // 2. 重置媒体标识
    self.sourceIdentifier = [NSString stringWithFormat:@"%lf", [NSDate date].timeIntervalSince1970];
    for (int i = 0; i < kBufferCount; i ++) {
        NSNotification *noti = [NSNotification notificationWithName:kNotificationShouldFillAudioQueueBuffer
                                                             object:nil
                                                           userInfo:@{@"sourceId": self.sourceIdentifier}];
        [[NSNotificationCenter defaultCenter] postNotification:noti];
    }
}

/// buffer 填充接口
/// 将生产者数据填充至 subBuffer 中
- (OSStatus) enqueueAudioBuffer:(AudioBuffer)buffer {
    [self.syncLock0 lock];
    
    // 生产者提供 buffer 原始大小
    int bigBufferSize = buffer.mDataByteSize;
    // 还未读取大小
    int bigBufferRemainSize = bigBufferSize;
    // 还未读取的生产者 buffer
    void* __nullable bigRemainBuffer = buffer.mData;
    
    OSStatus status = 1;
    for (int i = 0; i < kSubBufferCount; i ++) {
        if (!_aqBuffers[i] || _aqBuffers[i]->mAudioDataByteSize <= 0) {
            _aqBuffers[i]->mAudioDataByteSize = bigBufferRemainSize > kSubBufferSize ? kSubBufferSize : bigBufferRemainSize;
            memcpy(_aqBuffers[i]->mAudioData,
                   bigRemainBuffer,
                   _aqBuffers[i]->mAudioDataByteSize);
            
            OSStatus qErr;
            if (self.isJustFetchPCM) {
                qErr = AudioQueueSetParameter(_aqInstance, kAudioQueueParam_Volume, 0);
                if (self.pcmCallback) {
                    AudioBuffer ioData;
                    ioData.mData = _aqBuffers[i]->mAudioData;
                    ioData.mNumberChannels = self.asbd.mChannelsPerFrame;
                    ioData.mDataByteSize = _aqBuffers[i]->mAudioDataByteSize;
                    self.pcmCallback(ioData);
                }
            }
            else {
                qErr = AudioQueueSetParameter(_aqInstance, kAudioQueueParam_Volume, 1);
            }
            if (qErr != noErr) {
                NSLog(@"【ERROR】AudioQueue 设置音量（%d）失败！！! %d",(int)self.isJustFetchPCM ,(int)qErr);
            }
            
            OSStatus aErr = AudioQueueEnqueueBuffer(_aqInstance, _aqBuffers[i], 0, NULL);
            if (aErr != noErr) {
                NSLog(@"【ERROR】buffer 入队列错误！！！ %d",(int)aErr);
            }
            status = noErr;
            
            bigBufferRemainSize = bigBufferRemainSize - _aqBuffers[i]->mAudioDataByteSize;
            bigRemainBuffer = bigRemainBuffer + _aqBuffers[i]->mAudioDataByteSize;
            
            if (bigBufferRemainSize <= 0) {
                break;
            }
        }
    }
    
    [self.syncLock0 unlock];
    if (status == noErr) {
        _didCacheOneBigBuffer = YES;
        if (_didCacheOneBigBuffer && _playFlag) {
            AudioQueueStart(_aqInstance, NULL);
            _playFlag = NO;
        }
    }
    return status;
}

- (void) play {
    _forbidCallback = NO;
    
    if (_didCacheOneBigBuffer) {
        AudioQueueStart(_aqInstance, NULL);
        _playFlag = NO;
    }
    else {
        _playFlag = YES;
    }
}

- (void) pause {
    AudioQueuePause(_aqInstance);
}

- (void) resume {
    // AudioQueueStart 可以多次连续调用，无副作用
    // 当前 AudioQueue 暂停后，在前台模式 AudioQueue 还有机会重启。比如被当前音乐打断，可以重启 AQ 恢复
    // 但是如果是系统级，比如来电，重启 AQ 会返回错误码
    AudioQueueStart(_aqInstance, NULL);
}

- (void) stop {
    _forbidCallback = YES;
    // 会触发 aqBufferDidReadCallback
    AudioQueueStop(_aqInstance, true);
    AudioQueueReset(_aqInstance);
}

- (void) releaseGC {
    cPcmPlaYer = nil;
}

- (void) dispose {
    AudioQueueFlush(_aqInstance);
    for(int i = 0; i < kSubBufferCount; i ++) {
        int result =  AudioQueueFreeBuffer(_aqInstance, _aqBuffers[i]);
        if (result != 0) {
            NSLog(@"【ERROR】Audio Queue Buffer free Error!!! %d", result);
        }
    }
    AudioQueueDispose(_aqInstance, YES);
}

#pragma mark - private methods
- (AudioStreamBasicDescription) defaultAsbd {
    AudioStreamBasicDescription asbd;
    memset(&asbd, 0, sizeof(asbd));
    asbd.mSampleRate = 44100;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    asbd.mChannelsPerFrame = 2;
    asbd.mFramesPerPacket = 1;
    asbd.mBitsPerChannel = 16;
    asbd.mBytesPerFrame = (asbd.mBitsPerChannel / 8) * asbd.mChannelsPerFrame;
    asbd.mBytesPerPacket = asbd.mBytesPerFrame * asbd.mFramesPerPacket;
    return asbd;
}

- (void) initAudioQueueAndBuffers {
    // 1. 创建 AudioQueue
    OSStatus qErr = AudioQueueNewOutput(&_asbd,
                                        aqBufferDidReadCallback,
                                        (__bridge void * _Nullable)(self),
                                        nil,
                                        nil,
                                        0,
                                        &_aqInstance);
    if (qErr != noErr) {
        NSLog(@"【ERROR】创建队列错误！！！ %d",(int)qErr);
    }
    
    qErr = AudioQueueAddPropertyListener(_aqInstance,
                                         kAudioQueueProperty_IsRunning,
                                         aqPropertyListenerCallback,
                                         (__bridge void * _Nullable)(self));
    if (qErr != noErr) {
        NSLog(@"【ERROR】监听 AudioQueue 失败！！！ %d",(int)qErr);
    }
    
    // 2. 创建缓冲数组
    for(int i = 0; i < kSubBufferCount; i ++) {
        OSStatus err =  AudioQueueAllocateBuffer(_aqInstance,
                                                 kSubBufferSize,
                                                 &_aqBuffers[i]);
        if (err != noErr) {
            NSLog(@"【ERROR】创建缓冲区数据错误！！！ %d",(int)err);
        }
    }
    // 3. 配置 AudioSession
    NSError *sErr = nil;
    AVAudioSession *as = [AVAudioSession sharedInstance];
    
    [as setCategory:AVAudioSessionCategoryPlayback
        withOptions:AVAudioSessionCategoryOptionMixWithOthers
              error:&sErr];
    
    [as setPreferredSampleRate:_asbd.mSampleRate error:&sErr];
    [[AVAudioSession sharedInstance] setActive:YES error:&sErr];
    if (sErr) {
        NSLog(@"【ERROR】AVAudioSession 配置错误: %@",sErr.localizedDescription);
    }
}

/// 检测是否应该告诉生产者提供数据
- (BOOL) shouldFillNewData {
    int count = 0;
    for(int i = 0; i < kSubBufferCount; i ++) {
        if (_aqBuffers[i]->mAudioDataByteSize <= 0) {
            count ++;
        }
    }
    if (count == kShouldFillDataCount0 || count == kShouldFillDataCount1) {
        return YES;
    }
    return NO;
}

/// 检查队列中的 buffer 是否全空
- (BOOL) buffersNULL {
    for(int i = 0; i < kSubBufferCount; i ++) {
        if (_aqBuffers[i]->mAudioDataByteSize > 0) {
            return NO;
        }
    }
    return YES;
}
@end
