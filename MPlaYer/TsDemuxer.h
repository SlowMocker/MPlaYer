//
//  TsDemuxer.h
//  MPlaYer
//
//  Created by 吴文豪 on 2020/8/20.
//  Copyright © 2020 吴文豪. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Error.h"

NS_ASSUME_NONNULL_BEGIN

@interface TsDemuxer : NSObject
/// ts 文件解封包
/// @note 音频只支持返回 mp3 和 aac | 视频只支持 h264
/// @param tsURL ts 文件网络 URL
/// @param handler 回调
+ (void) demuxNetTsFile:(NSURL *)tsURL handler:(void (^)(NSURL *aacOrMp3URL, NSURL *h264URL, Error *error))handler;
@end

NS_ASSUME_NONNULL_END
