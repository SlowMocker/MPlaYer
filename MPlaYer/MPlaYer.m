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

#import "TSEngine.h"

@interface MPlaYer ()<TSEngineProtocol, STKAudioPlayerDelegate>
@property (nonatomic , strong) STKAudioPlayer *audioPlayer;
@property (nonatomic , strong) TSEngine *tsEngine;
@property (nonatomic , strong) NSMutableArray<NSURL *> *localAACURLList;
@end

@implementation MPlaYer
{
    BOOL _isLive;
}

- (id) init {
    self = [super init];
    if (self) {
        _audioPlayer = [[STKAudioPlayer alloc] initWithOptions:(STKAudioPlayerOptions){ .flushQueueOnSeek = YES, .enableVolumeMixer = NO, .equalizerBandFrequencies = {50, 100, 200, 400, 800, 1600, 2600, 16000} }];
        _audioPlayer.delegate = self;
        _audioPlayer.meteringEnabled = YES;
        _audioPlayer.volume = 1;

        _tsEngine = [[TSEngine alloc]init];
        _tsEngine.delegate = self;
        _localAACURLList = NSMutableArray.new;
    }
    return self;
}

- (void) fetchLiveStream:(NSURL *)url
                 handler:(void (^)(UInt32 channelsPerFrame, UInt32 bytesPerFrame, UInt32 frameCount, void * _Nonnull frames))handler {
    _isLive = YES;
    self.localAACURLList = NSMutableArray.new;
    self.tsEngine.m3u8URL = url;
    [self.tsEngine start];

    [self.audioPlayer appendFrameFilterWithName:@"wuwenhao" block:^(UInt32 channelsPerFrame, UInt32 bytesPerFrame, UInt32 frameCount, void * _Nonnull frames) {
        NSLog(@"PCM { channelsPerFrame : %d | bytesPerFrame : %d | frameCount : %d}", (int)channelsPerFrame, (int)bytesPerFrame, (int)frameCount);
    }];
}

#pragma mark - TSEngineProtocol
- (void) tsEngine:(TSEngine *)engine didReceiveNewAudioPath:(NSURL *)url {
    if (_isLive) {
        [self.audioPlayer queueURL:url];
        NSLog(@"\n Enqueue URL: %@", [url.path substringFromIndex:100]);
    }
}

#pragma mark - STKAudioPlayerDelegate
- (void)audioPlayer:(STKAudioPlayer *)audioPlayer didFinishBufferingSourceWithQueueItemId:(NSObject *)queueItemId {
    if (_isLive) {
        [self.tsEngine start];
    }
}

/// Raised when an item has started playing
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didStartPlayingQueueItemId:(NSObject*)queueItemId {

}
/// Raised when the state of the player has changed
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer stateChanged:(STKAudioPlayerState)state previousState:(STKAudioPlayerState)previousState {

}
/// Raised when an item has finished playing
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didFinishPlayingQueueItemId:(NSObject*)queueItemId withReason:(STKAudioPlayerStopReason)stopReason andProgress:(double)progress andDuration:(double)duration {

}
/// Raised when an unexpected and possibly unrecoverable error has occured (usually best to recreate the STKAudioPlauyer)
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer unexpectedError:(STKAudioPlayerErrorCode)errorCode {

}
@end
