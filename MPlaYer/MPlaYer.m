//
//  MPlaYer.m
//  MPlaYer
//
//  Created by 吴文豪 on 2020/8/17.
//  Copyright © 2020 吴文豪. All rights reserved.
//

#import "MPlaYer.h"
#import "STKAudioPlayer.h"
#import "STKAutoRecoveringHTTPDataSource.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "SYstemEx.h"

#import "TsHandler.h"

@interface MPlaYer ()<TsHandlerProtocol, STKAudioPlayerDelegate>

/// 音频播放器
@property (nonatomic , strong) STKAudioPlayer *audioPlayer;
@property (nonatomic , strong) TsHandler *tsHandler;
@property (nonatomic , assign) MPlaYerStatus status;
@end

@implementation MPlaYer
{
    // 是否是 HTTP Live Stream
    BOOL _isHLS;
}

- (void) dealloc {
    NSLog(@"\n\n\n**************************** MPlaYer dealloc!!! ****************************\n\n\n");
}

- (id) init {
    self = [super init];
    if (self) {
        STKAudioPlayerOptions options;
        options = (STKAudioPlayerOptions){ .flushQueueOnSeek = YES, .enableVolumeMixer = YES, .equalizerBandFrequencies = {50, 100, 200, 400, 800, 1600, 2600, 16000}};
        _audioPlayer = [[STKAudioPlayer alloc] initWithOptions:options];
        _audioPlayer.delegate = self;
        _audioPlayer.meteringEnabled = YES;
        _audioPlayer.volume = 1;
        __weak typeof(self) weakSelf = self;
        [_audioPlayer appendFrameFilterWithName:@"MosiTech"
                                          block:^(UInt32 channelsPerFrame, UInt32 bytesPerFrame, UInt32 frameCount, void * _Nonnull frames) {
            __strong typeof(weakSelf) self = weakSelf;
            if (self.pcmCallback) {
                AudioBuffer ioData;
                ioData.mData = frames;
                ioData.mNumberChannels = channelsPerFrame;
                ioData.mDataByteSize = bytesPerFrame * frameCount;
                self.pcmCallback(ioData);
            }
        }];

        _tsHandler = [[TsHandler alloc]init];
        _tsHandler.delegate = self;
    }
    return self;
}

/// 对于 HLS ，不管是 play 还是 resume，执行之前都当作重新播放
- (void) play:(NSURL *)url {
    if ([url isAvalidM3U8URL]) {
        // HLS
        _isHLS = YES;
        
        self.tsHandler.m3u8URL = url;
        
        [self.tsHandler flush];
        [self.audioPlayer stop];
        // start 内部只是 queue source，只有 stop 状态才会自动 play
        [self.tsHandler start];
    }
    else {
        _isHLS = NO;
        [self.audioPlayer playURL:url];
    }
}

- (void) resume {
    if (_isHLS) {
        [self.tsHandler flush];
        [self.audioPlayer stop];
        [self.tsHandler start];
    }
    else {
        [self.audioPlayer resume];
    }
}

- (void) pasue {
    [self.audioPlayer pause];
}

- (void) stop {
    [self.audioPlayer stop];
}

- (void) setIsJustFetchPCM:(BOOL)justFetchPCM {
    _isJustFetchPCM = justFetchPCM;
    if (_isJustFetchPCM) {
        self.audioPlayer.volume = 0;
    }
    else {
        self.audioPlayer.volume = 1;
    }
}

#pragma mark - TsHandlerProtocol
- (void) tsHandler:(TsHandler *)engine didReceiveNewAudioPath:(NSURL *)url {
    if (_isHLS) {
        [self.audioPlayer queueURL:url];
    }
}

#pragma mark - STKAudioPlayerDelegate
/// Raised when an item has started playing
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didStartPlayingQueueItemId:(NSObject*)queueItemId {
//    NSLog(@"\n**** didStartPlayingQueueItemId");
}
/// Raised when an item has finished buffering (may or may not be the currently playing item)
/// This event may be raised multiple times for the same item if seek is invoked on the player
/// 当 queueItemId 对应的媒体文件完成缓存时调用
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didFinishBufferingSourceWithQueueItemId:(NSObject*)queueItemId {
//    NSLog(@"\n**** didFinishBufferingSourceWithQueueItemId");
}
/// Raised when the state of the player has changed
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer stateChanged:(STKAudioPlayerState)state previousState:(STKAudioPlayerState)previousState {
//    NSLog(@"\n**** stateChanged | from %d to %d", (int)previousState, (int)state);
    /*
     0 -> STKAudioPlayerStateReady,
     1 -> STKAudioPlayerStateRunning = 1,
     3 -> STKAudioPlayerStatePlaying = (1 << 1) | STKAudioPlayerStateRunning,
     5 -> STKAudioPlayerStateBuffering = (1 << 2) | STKAudioPlayerStateRunning,
     9 -> STKAudioPlayerStatePaused = (1 << 3) | STKAudioPlayerStateRunning,
     16 -> STKAudioPlayerStateStopped = (1 << 4),
     32 -> STKAudioPlayerStateError = (1 << 5),
     64 -> STKAudioPlayerStateDisposed = (1 << 6)
     */
    switch (state) {
        case STKAudioPlayerStatePlaying: {
            self.status = MPlaYerStatusPLAYING;
            if (self.playerStatusCallback) self.playerStatusCallback(MPlaYerStatusPLAYING);
            break;
        }
        case STKAudioPlayerStatePaused: {
            self.status = MPlaYerStatusPAUSE;
            if (self.playerStatusCallback) self.playerStatusCallback(MPlaYerStatusPAUSE);
            break;
        }
        case STKAudioPlayerStateDisposed: {
            self.status = MPlaYerStatusDISPOSAL;
            if (self.playerStatusCallback) self.playerStatusCallback(MPlaYerStatusDISPOSAL);
            break;
        }
        case STKAudioPlayerStateStopped: {
            self.status = MPlaYerStatusSTOP;
            if (self.playerStatusCallback) self.playerStatusCallback(MPlaYerStatusSTOP);
            break;
        }
        case STKAudioPlayerStateBuffering:
        case STKAudioPlayerStateRunning:
        case STKAudioPlayerStateReady: {
            if (_isHLS) {
                if (!(previousState == STKAudioPlayerStatePlaying && state == STKAudioPlayerStateBuffering)) {
                    self.status = MPlaYerStatusLOADING;
                    if (self.playerStatusCallback) self.playerStatusCallback(MPlaYerStatusLOADING);
                }
            }
            else {
                self.status = MPlaYerStatusLOADING;
                if (self.playerStatusCallback) self.playerStatusCallback(MPlaYerStatusLOADING);
            }
            break;
        }
            
        default:
            break;
    }
}
/// Raised when an item has finished playing
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didFinishPlayingQueueItemId:(NSObject*)queueItemId withReason:(STKAudioPlayerStopReason)stopReason andProgress:(double)progress andDuration:(double)duration {
    /* 当 id 正常播放结束时的打印
     **** didFinishPlayingQueueItemId
     id : http://music.163.com/song/media/outer/url?id=569212211.mp3
     stopReason : 0
     progress : 275.325964
     duration : 0.000000
     */
    if (_isHLS) {
        [self.tsHandler start];
    }
    NSLog(@"\n**** didFinishPlayingQueueItemId \n id : %@ \n stopReason : %d \n progress : %lf \n duration : %lf",queueItemId, (int)stopReason, progress, duration);
}
/// Raised when an unexpected and possibly unrecoverable error has occured (usually best to recreate the STKAudioPlauyer)
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer unexpectedError:(STKAudioPlayerErrorCode)errorCode {
    NSLog(@"\n**** 【ERROR】 unexpectedError | %d", (int)errorCode);
}
@end
