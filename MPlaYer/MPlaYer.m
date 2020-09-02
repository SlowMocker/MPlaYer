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
@property (nonatomic , strong) TsHandler *tsEngine;
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
        options = (STKAudioPlayerOptions){ .flushQueueOnSeek = YES, .enableVolumeMixer = NO, .equalizerBandFrequencies = {50, 100, 200, 400, 800, 1600, 2600, 16000}};
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

        _tsEngine = [[TsHandler alloc]init];
        _tsEngine.delegate = self;
    }
    return self;
}

- (void) play:(NSURL *)url {
    if ([url isAvalidM3U8URL]) {
        // HLS
        _isHLS = YES;
        
        self.tsEngine.m3u8URL = url;
        [self.tsEngine start];
    }
    else {
        _isHLS = NO;
        [self.audioPlayer playURL:url];
    }
}

- (void) pasue {
    
}

- (void) stop {
    
}

#pragma mark - TSEngineProtocol
- (void) tsHandler:(TsHandler *)engine didReceiveNewAudioPath:(NSURL *)url {
    if (_isHLS) {
        [self.audioPlayer queueURL:url];
//        NSLog(@"\n Enqueue URL: %@", [url.path substringFromIndex:100]);
    }
}

#pragma mark - STKAudioPlayerDelegate
- (void) audioPlayer:(STKAudioPlayer *)audioPlayer didFinishBufferingSourceWithQueueItemId:(NSObject *)queueItemId {
    if (_isHLS) {
        [self.tsEngine start];
    }
}
/// Raised when an item has started playing
- (void) audioPlayer:(STKAudioPlayer*)audioPlayer didStartPlayingQueueItemId:(NSObject*)queueItemId {

}
/// Raised when the state of the player has changed
- (void) audioPlayer:(STKAudioPlayer*)audioPlayer stateChanged:(STKAudioPlayerState)state previousState:(STKAudioPlayerState)previousState {

}
/// Raised when an item has finished playing
- (void) audioPlayer:(STKAudioPlayer*)audioPlayer didFinishPlayingQueueItemId:(NSObject*)queueItemId
          withReason:(STKAudioPlayerStopReason)stopReason
         andProgress:(double)progress andDuration:(double)duration {

}
/// Raised when an unexpected and possibly unrecoverable error has occured (usually best to recreate the STKAudioPlauyer)
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer unexpectedError:(STKAudioPlayerErrorCode)errorCode {

}
@end
