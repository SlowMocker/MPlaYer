//
//  SYstemEx.h
//  MPlaYer
//
//  Created by wuwenhao on 2020/8/20.
//  Copyright © 2020 MOSI. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MOSISYstemEx : NSObject

@end

@interface NSURL (Ex)

/// URL 是否是合法的 m3u8 路径
- (BOOL) isAvalidM3U8URL;

/// URL 是否是合法的 ts 网络路径
- (BOOL) isAvalidTsNetURL;
@end

NS_ASSUME_NONNULL_END
