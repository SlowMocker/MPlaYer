//
//  M3U8Parser.h
//  MPlaYer
//
//  Created by wuwenhao on 2020/8/20.
//  Copyright © 2020 MOSI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Error.h"

NS_ASSUME_NONNULL_BEGIN

@interface M3U8Parser : NSObject

/// 处理 m3u8 路径
/// @param m3u8URL m3u8 URL
/// @param handler 回调
+ (void)m3u8Parser:(NSURL *)m3u8URL handler:(void (^)(NSArray<NSURL *> * __nullable tsNetURLs, Error *err))handler;

@end

NS_ASSUME_NONNULL_END
