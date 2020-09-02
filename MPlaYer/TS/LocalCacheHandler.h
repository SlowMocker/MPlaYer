//
//  LocalCacheHandler.h
//  MPlaYer
//
//  Created by 吴文豪 on 2020/8/20.
//  Copyright © 2020 吴文豪. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LocalCacheHandler : NSObject

/// 清除 TS 缓存
+ (void) cleanTsCache;
/// 创建一个唯一的 Cache Path
+ (NSString *) uniqueCacheTsPath;
/// 创建一个唯一的临时 Path
+ (NSString *) uniqueTempTsPath;

/// 删除指定路径下的文件或者文件夹
+ (void) cleanPath:(NSString *)path;

+ (NSString *) mosiLinkCacheTsDir;
@end

NS_ASSUME_NONNULL_END
