//
//  MPlaYer.h
//  MPlaYer
//
//  Created by 吴文豪 on 2020/8/17.
//  Copyright © 2020 吴文豪. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN
@interface MPlaYer : NSObject

/// PCM 数据独立回调
@property (nonatomic , copy) void (^pcmCallback)(AudioBuffer ioData);
/// 播放器状态回调
@property (nonatomic , copy) void (^playerStatusCallback)(void);

/// 播放
- (void) play:(NSURL *)url;
/// 暂停
- (void) pasue;
/// 停止
- (void) stop;
@end
NS_ASSUME_NONNULL_END
