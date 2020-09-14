//
//  MPcmPlaYer.m
//  QPlayAutoDemo
//
//  Created by iSmicro on 2020/8/30.
//  Copyright © 2020 wuwenhao. All rights reserved.
//

#import "MPcmPlaYer.h"

MPcmPlaYer *cPcmPlaYer = nil;

@interface MPcmPlaYer()
// asbd
@property (nonatomic , assign) AudioStreamBasicDescription asbd;
// 填充 buffer 同步锁
@property (nonatomic , strong) NSLock *syncLock;
// 播放文件 id
@property (nonatomic , copy) NSString *sourceIdentifier;

@property (nonatomic , assign) BOOL isRunning;
@end

#define kBufferCount 3
// 一个 buffer 250K
#define kBufferSize (1024*250)


@implementation MPcmPlaYer
{
    /// AudioQueue 实例
    AudioQueueRef _aqInstance;
    /// buffers
    AudioQueueBufferRef _aqBuffers[kBufferCount];
    
    BOOL _forbbidCallback;
}

- (id) init {
    self = [super init];
    if (self) {
        self.asbd = [self defaultAsbd];
        self.syncLock = [[NSLock alloc]init];
        cPcmPlaYer = self;
        
        _forbbidCallback = NO;
    }
    return self;
}

void aqBufferDidReadCallback(void * __nullable inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
    
//    memset(inBuffer->mAudioData, 0, kBufferSize);
    inBuffer->mAudioDataByteSize = 0;
    
    if (cPcmPlaYer) {
        if (cPcmPlaYer.allBufferNullCallback && [cPcmPlaYer buffersNULL]) {
            cPcmPlaYer.allBufferNullCallback();
        }
        if (cPcmPlaYer->_forbbidCallback) {
            return;
        }
        NSNotification *noti = [NSNotification notificationWithName:kNotificationShouldFillAudioQueueBuffer
                                                             object:nil
                                                           userInfo:@{@"sourceId": cPcmPlaYer.sourceIdentifier}];
        [[NSNotificationCenter defaultCenter] postNotification:noti];
    }
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
    NSLog(@"\n\n\n*******************************************************************MPcmPlaYer dealloc!!! Happiness Maybe!!!\n\n\n*");
}

#pragma mark - public methods
- (void) prepareToPlay:(AudioStreamBasicDescription)asbd {
    
    _forbbidCallback = NO;
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
        if (!self->_aqBuffers[i] || self->_aqBuffers[i]->mAudioDataByteSize <= 0) {
            NSNotification *noti = [NSNotification notificationWithName:kNotificationShouldFillAudioQueueBuffer
                                                                 object:nil
                                                               userInfo:@{@"sourceId": self.sourceIdentifier}];
            [[NSNotificationCenter defaultCenter] postNotification:noti];
        }
    }
}

/// buffer 填充接口
- (OSStatus) enqueueAudioBuffer:(AudioBuffer)buffer {
    [self.syncLock lock];
    // 填充数据到 buffer
    OSStatus status = 1;
    for (int i = 0; i < kBufferCount; i ++) {
        // 还未填充过数据
        if (!_aqBuffers[i] || _aqBuffers[i]->mAudioDataByteSize <= 0) {
            _aqBuffers[i]->mAudioDataByteSize = buffer.mDataByteSize;
            memcpy(_aqBuffers[i]->mAudioData,
                   buffer.mData,
                   buffer.mDataByteSize);
            
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
                NSLog(@"【ERROR AudioQueue 设置音量（%d）失败！！! %d",(int)self.isJustFetchPCM ,(int)qErr);
            }
            
            OSStatus aErr = AudioQueueEnqueueBuffer(_aqInstance, _aqBuffers[i], 0, NULL);
            if (aErr != noErr) {
                NSLog(@"【ERROR】buffer 入队列错误！！！ %d",(int)aErr);
            }
            status = noErr;
            
            break;
        }
    }
    [self.syncLock unlock];
    return status;
}

- (void) play {
    _forbbidCallback = NO;
    // AudioQueueStart 可以多次连续调用，无副作用
    // 当前 AudioQueue 暂停后，在前台模式 AudioQueue 还有机会重启。比如被当前音乐打断，可以重启 AQ 恢复
    // 但是如果是系统级，比如来电，重启 AQ 会返回错误码
    AudioQueueStart(_aqInstance, NULL);
}

- (void) pause {
    AudioQueuePause(_aqInstance);
}

- (void) resume {
    AudioQueueStart(_aqInstance, NULL);
}

- (void) stop {
    _forbbidCallback = YES;
    // 会触发 aqBufferDidReadCallback
    AudioQueueStop(_aqInstance, true);
    AudioQueueReset(_aqInstance);
}

- (void) releaseGC {
    cPcmPlaYer = nil;
}

- (void) setAsbd:(AudioStreamBasicDescription)asbd {
    _asbd = asbd;
}

- (void) dispose {
    AudioQueueFlush(_aqInstance);
    for(int i = 0; i < kBufferCount; i ++) {
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
    for(int i = 0; i < kBufferCount; i ++) {
        OSStatus err =  AudioQueueAllocateBuffer(_aqInstance,
                                                 kBufferSize,
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

/// 检查队列中的 buffer 是否全空
- (BOOL) buffersNULL {
    for(int i = 0; i < kBufferCount; i ++) {
        if (_aqBuffers[i]->mAudioDataByteSize > 0) {
            return NO;
        }
    }
    return YES;
}
@end
