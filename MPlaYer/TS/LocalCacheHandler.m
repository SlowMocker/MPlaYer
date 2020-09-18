//
//  LocalCacheHandler.m
//  MPlaYer
//
//  Created by wuwenhao on 2020/8/20.
//  Copyright © 2020 MOSI. All rights reserved.
//

#import "LocalCacheHandler.h"

@implementation LocalCacheHandler


/// 清除 TS 缓存
+ (void) cleanTsCache {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:[self mosiLinkTempTsDir]]) {
        [fm removeItemAtPath:[self mosiLinkTempTsDir] error:nil];
    }
    if ([fm fileExistsAtPath:[self mosiLinkCacheTsDir]]) {
        [fm removeItemAtPath:[self mosiLinkCacheTsDir] error:nil];
    }
}

+ (void) cleanPath:(NSString *)path {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:path]) {
        [fm removeItemAtPath:path error:nil];
    }
}

+ (NSString *) uniqueCacheTsPath {
    NSString *path = [[self mosiLinkCacheTsDir] stringByAppendingPathComponent:[self udid]];
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
    return path;
}

+ (NSString *) uniqueTempTsPath {
    NSString *path = [[self mosiLinkTempTsDir] stringByAppendingPathComponent:[self udid]];
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
    return path;
}

#pragma mark - private methods
/// ts 文件解码后文件存放 dir
+ (NSString *) mosiLinkCacheTsDir {
    NSString *path = [[self mosiLinkTempRootDir] stringByAppendingPathComponent:@"TS"];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if (![fm fileExistsAtPath:path isDirectory:&isDir]) {
        [fm createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return path;
}

/// 临时 TS 问价存放 dir
+ (NSString *) mosiLinkTempTsDir {
    NSString *path = [[self mosiLinkTempRootDir] stringByAppendingPathComponent:@"TS"];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if (![fm fileExistsAtPath:path isDirectory:&isDir]) {
        [fm createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return path;
}

/// 在 Cache 文件夹中的 root 文件夹
+ (NSString *) mosiLinkCacheRootDir {
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *mosiCacheDir = [NSString stringWithFormat:@"%@/MOSILINK", cacheDir];

    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if (![fm fileExistsAtPath:mosiCacheDir isDirectory:&isDir]) {
        [fm createDirectoryAtPath:mosiCacheDir withIntermediateDirectories:NO attributes:nil error:nil];
    }

    return mosiCacheDir;
}

/// 在 Document 文件夹中的 root 文件夹
+ (NSString *) mosiLinkDocRootDir {
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *mosiDocDir = [NSString stringWithFormat:@"%@/MOSILINK", docDir];

    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if (![fm fileExistsAtPath:mosiDocDir isDirectory:&isDir]) {
        [fm createDirectoryAtPath:mosiDocDir withIntermediateDirectories:NO attributes:nil error:nil];
    }

    return mosiDocDir;
}

/// 在 Temp 文件夹中的 root 文件夹
+ (NSString *) mosiLinkTempRootDir {
    NSString *tempDir = NSTemporaryDirectory();
    NSString *mosiTempDir = [NSString stringWithFormat:@"%@/MOSILINK", tempDir];

    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if (![fm fileExistsAtPath:mosiTempDir isDirectory:&isDir]) {
        [fm createDirectoryAtPath:mosiTempDir withIntermediateDirectories:NO attributes:nil error:nil];
    }

    return mosiTempDir;
}

/// 获取 udid
/// @note udid 获取每次都不一样
+ (NSString *) udid {
    return [[NSProcessInfo processInfo] globallyUniqueString];
}

@end
