//
//  TsDemuxer.m
//  MPlaYer
//
//  Created by 吴文豪 on 2020/8/20.
//  Copyright © 2020 吴文豪. All rights reserved.
//

#import "TsDemuxer.h"
#import "ts.h"
#import "LocalCacheHandler.h"
#import "Downloader.h"
#import "SYstemEx.h"

static double const UndefinedFPS = -1.0;

@implementation TsDemuxer

+ (void) demuxNetTsFile:(NSURL *)tsURL handler:(void (^)(NSURL *, NSURL *, Error *))handler {

    if (![tsURL isAvalidTsNetURL]) {
        if (handler) handler(nil, nil, [Error paramError:@"ts 路径不合法（不包含\".ts\"字符串）"]);
    }

    // 临时路径，解析完后接口内部清理
    NSString *tempDir = [LocalCacheHandler uniqueTempTsPath];
    NSURL *tempURL = [NSURL fileURLWithPath:[tempDir stringByAppendingPathComponent:@"burst.ts"]];

    NSURL * (^destinationPathHandler)(NSURL * _Nonnull, NSURLResponse * _Nonnull) =
    ^ (NSURL *targetPath, NSURLResponse *response) {
        return tempURL;
    };

    void (^completionHandler)(NSURLResponse * _Nonnull, NSURL * _Nonnull, NSError * _Nonnull) =
    ^ (NSURLResponse *response, NSURL *filePath, NSError *error) {
        if (!error && ((NSHTTPURLResponse *)response).statusCode == 200) {

            [self demuxLocalTsFiles:@[filePath] handler:^(NSURL *aacOrMp3URL, NSURL *h264URL, Error *error) {

                if (handler) handler(aacOrMp3URL, h264URL, error);

                // 删除临时路径及文件
                [LocalCacheHandler cleanPath:tempDir];
            }];
        }
        else {

            if (handler) handler(nil, nil, [Error errorFromNSError:error]);

            // 删除临时路径及文件
            [LocalCacheHandler cleanPath:tempDir];
        }
    };

    AFHTTPSessionManager *session  = [AFHTTPSessionManager manager];
    NSURLRequest *request = [NSURLRequest requestWithURL:tsURL];
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request
                                                                    progress: nil
                                                                 destination:destinationPathHandler
                                                           completionHandler:completionHandler];
    [downloadTask resume];
}

+ (void) demuxLocalTsFiles:(NSArray<NSURL *> *) tsURLs handler:(void (^)(NSURL *, NSURL *, Error *)) handler {

    // 参数校验 0
    if (tsURLs.count <= 0) {
        handler(nil, nil, [Error paramError:@"参数错误"]);
        return;
    }
    // 参数校验 1
    [tsURLs enumerateObjectsUsingBlock:^(NSURL * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj.absoluteString.lowercaseString containsString:@".ts"]) {
            handler(nil, nil, [Error paramError:@"ts 文件格式错误"]);
            return;
        }
    }];

    // demux
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        dispatch_async(queue, ^(void) {

            int demuxStatus = 0;
            // TS 解封包存储路径
            NSURL *cacheTsDirURL = [NSURL fileURLWithPath:[LocalCacheHandler mosiLinkCacheTsDir]];
            double video_fps = UndefinedFPS;

            ts::demuxer demuxer;
            demuxer.parse_only = false;
            demuxer.es_parse = false;
            demuxer.dump = 0;
            demuxer.av_only = false;
            demuxer.channel = 0;
            demuxer.pes_output = false;
            demuxer.prefix = [[[NSProcessInfo processInfo] globallyUniqueString] UTF8String];
            demuxer.dst = [[cacheTsDirURL path] cStringUsingEncoding:[NSString defaultCStringEncoding]];

            for (int i = 0; i < tsURLs.count; i ++) {
                demuxStatus += demuxer.demux_file([[tsURLs[i] path] UTF8String], &video_fps);
            }

            NSString *fileName = [NSString stringWithFormat:@"%s",demuxer.prefix.c_str()];
            NSString *audioType = [NSString stringWithFormat:@"%s",demuxer.type()];

            dispatch_async(dispatch_get_main_queue(), ^(void) {
                // demux success
                if (demuxStatus == 0) {

                    NSString *audioFileName = [NSString stringWithFormat:@"%@%@",fileName, audioType];
                    NSString *audioPath = [cacheTsDirURL.path stringByAppendingPathComponent:audioFileName];
                    NSURL *returnAudioURL = [NSURL fileURLWithPath:audioPath];

                    NSURL *returnVideoURL = nil;
                    if (video_fps != UndefinedFPS) {
                        NSString *videoFileName = [NSString stringWithFormat:@"%@h264",fileName];
                        NSString *videoPath = [cacheTsDirURL.path stringByAppendingPathComponent:videoFileName];
                        returnVideoURL = [NSURL fileURLWithPath:videoPath];
                    }

                    handler(returnAudioURL, returnVideoURL, [Error success]);
                }
                else {
                    handler(nil, nil, [Error demuxError:@"ts 解封包失败"]);
                }

                [tsURLs enumerateObjectsUsingBlock:^(NSURL * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    [[NSFileManager defaultManager] removeItemAtURL:obj error:nil];
                }];
            });
        });
}
@end
