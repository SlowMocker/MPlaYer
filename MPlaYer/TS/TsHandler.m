//
//  TSEngine.m
//  MPlaYer
//
//  Created by 吴文豪 on 2020/8/18.
//  Copyright © 2020 吴文豪. All rights reserved.
//

#import "TsHandler.h"
#import "M3U8Parser.h"
#import "TsDemuxer.h"
#import "LocalCacheHandler.h"


@interface TsHandler()

// 切换 m3u8 路径时，清空所有数据
- (void) flush;

@property (nonatomic , strong) NSOperationQueue *opQueue;
// 缓存的 ts net url list
// .count <= 9
@property (nonatomic , strong) NSMutableArray<NSURL *> *tsNetURLList;
// 处理好的 .aac list
// .count <= 6
@property (nonatomic , strong) NSMutableArray<NSURL *> *localURLList;

@end

@implementation TsHandler

- (void) start {

    [M3U8Parser m3u8Parser:self.m3u8URL handler:^(NSArray<NSURL *> * _Nullable tsNetURLs, Error * _Nonnull err) {

        if ([err isSuccess]) {

            for (int i = 0; i < tsNetURLs.count; i ++) {
                if ([self isNewTSURL:tsNetURLs[i]]) {

                    NSLog(@"New URL: %@", tsNetURLs[i]);

                    NSOperation *op = [NSBlockOperation blockOperationWithBlock:^{
                        __block BOOL finish = NO;

                        [TsDemuxer demuxNetTsFile:tsNetURLs[i]
                                          handler:^(NSURL * _Nonnull aacOrMp3URL, NSURL * _Nonnull h264URL, Error * _Nonnull error) {

                            if ([error isSuccess]) {
                                if ([self.delegate respondsToSelector:@selector(tsHandler:didReceiveNewAudioPath:)]) {
                                    [self.delegate tsHandler:self didReceiveNewAudioPath:aacOrMp3URL];
                                }
                                [self cacheAACLocalURL:aacOrMp3URL];
                            }
                            finish = YES;
                        }];
                        while (!finish) {
                            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
                        }

                    }];
                    [self.opQueue addOperation:op];
                }
            }
        }
    }];
}

/// 是否是新的需要去请求的 ts 下载路径
- (BOOL) isNewTSURL:(NSURL *)url {
    if (url) {
        __block BOOL isNew = YES;
        [self.tsNetURLList enumerateObjectsUsingBlock:^(NSURL * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([url.path isEqualToString:obj.path]) {
                isNew  = NO;
                *stop = YES;
            }
        }];

        if (isNew) {
            [self cacheTSNetURL:url];

            return YES;
        }
    }

    return NO;
}

- (void) flush {
    // 取消所有操作
    [self.opQueue cancelAllOperations];
    // 重新初始化 tsQueue
    self.opQueue = [[NSOperationQueue alloc]init];
    self.opQueue.maxConcurrentOperationCount = 1;

    self.tsNetURLList = NSMutableArray.new;
    self.localURLList = NSMutableArray.new;

    [LocalCacheHandler cleanTsCache];
}

- (void) cacheTSNetURL:(NSURL *)url {
    [self.tsNetURLList addObject:url];
    if (self.tsNetURLList.count > 9) {
        [self.tsNetURLList removeObjectAtIndex:0];
    }
}

- (void) cacheAACLocalURL:(NSURL *)url {
    [self.localURLList addObject:url];
    if (self.localURLList.count > 6) {

        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:self.localURLList[0].path]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtURL:self.localURLList[0] error:&error];
            if (error) {
                NSLog(@"[ERROR]: 移除本地 aac 文件异常！");
            }
        }

        [self.localURLList removeObjectAtIndex:0];
    }
}

- (void) setM3u8URL:(NSURL *)m3u8URL {
    if (m3u8URL) {
        _m3u8URL = m3u8URL;
        [self flush];
    }
}

@end
