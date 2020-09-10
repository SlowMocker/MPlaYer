//
//  MPcmPlaYer.m
//  QPlayAutoDemo
//
//  Created by iSmicro on 2020/8/30.
//  Copyright © 2020 腾讯音乐. All rights reserved.
//

#import "MPcmPlaYer.h"

@interface MPcmPlaYer()

@property (nonatomic, strong) NSLock *syncLock;

/// 当前播放状态
@property (nonatomic , assign) MPlaYerStatus status;

@end

#define kBufferCount 5
// 一个 buffer 100K
#define kBufferSize (1024*100)


MPcmPlaYer *mPcmPlaYer = nil;

@implementation MPcmPlaYer
{
    /// AudioQueue 实例
    AudioQueueRef _aqInstance;
    /// buffers
    AudioQueueBufferRef _aqBuffers[kBufferCount];
}

- (id) init {
    self = [super init];
    if (self) {
        self.asbd = [self defaultAsbd];
        self.syncLock = [[NSLock alloc]init];
        mPcmPlaYer = self;
        
        [self initAudioQueueAndBuffers];
        
        [self callbackStatus:MPlaYerStatusLOADING];
    }
    return self;
}

void aqBufferDidReadCallback(void * __nullable inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
    
    memset(inBuffer->mAudioData, 0, kBufferSize);
    inBuffer->mAudioDataByteSize = 0;
    
    if (mPcmPlaYer.status == MPlaYerStatusSTOP) {
        return;
    }
    
    if ([mPcmPlaYer buffersNULL]) {
        [mPcmPlaYer callbackStatus:MPlaYerStatusSTOP];
        return;
    }
    
    NSNotification *noti = [NSNotification notificationWithName:kNotificationShouldFillAudioQueueBuffer
                                                         object:nil
                                                       userInfo:@{@"player": mPcmPlaYer}];
    [[NSNotificationCenter defaultCenter] postNotification:noti];
}

void aqPropertyListenerCallback(void * __nullable inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID) {
    MPcmPlaYer *instance = (__bridge MPcmPlaYer *)inUserData;
    UInt32 isRunning = 0;
    UInt32 size = sizeof(isRunning);
    
    if (instance == NULL) return;
    // 停止可能需要调用 stop 触发
    OSStatus err = AudioQueueGetProperty(inAQ, kAudioQueueProperty_IsRunning, &isRunning, &size);
    if (err) {
        NSLog(@"PCM player running: NO");
    }
    else {
        NSLog(@"PCM player running: YES");
        
    }
}

- (void) dealloc {
    NSLog(@"MPcmPlaYer dealloc!!!");
}

#pragma mark - public methods
- (void) prepareToPlay {
    for (int i = 0; i < kBufferCount; i ++) {
        if (!self->_aqBuffers[i] || self->_aqBuffers[i]->mAudioDataByteSize <= 0) {
            NSNotification *noti = [NSNotification notificationWithName:kNotificationShouldFillAudioQueueBuffer
                                                                 object:nil
                                                               userInfo:@{@"player": mPcmPlaYer}];
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
    if (status == noErr && self.status == MPlaYerStatusLOADING) {
        [self callbackStatus:MPlaYerStatusPLAYING];
    }
    return status;
}

- (void) play {
    // AudioQueueStart 可以多次连续调用，无副作用
    // 当前 AudioQueue 暂停后，在前台模式 AudioQueue 还有机会重启。比如被当前音乐打断，可以重启 AQ 恢复
    // 但是如果是系统级，比如来电，重启 AQ 会返回错误码
    AudioQueueStart(_aqInstance, NULL);
}

- (void) pause {
    AudioQueuePause(_aqInstance);
    [self callbackStatus:MPlaYerStatusPAUSE];
}

- (void) resume {
    AudioQueueStart(_aqInstance, NULL);
    [self callbackStatus:MPlaYerStatusPLAYING];
}

- (void) stop {
    // 会触发 aqBufferDidReadCallback
    AudioQueueStop(_aqInstance, true);
    [self callbackStatus:MPlaYerStatusSTOP];
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

- (void) callbackStatus:(MPlaYerStatus)status {
    self.status = status;
    if (self.playerStatusCallback) {
        self.playerStatusCallback(self.status);
    }
}

- (BOOL) buffersNULL {
    for(int i = 0; i < kBufferCount; i ++) {
        if (_aqBuffers[i]->mAudioDataByteSize > 0) {
            return NO;
        }
    }
    return YES;
}
@end
