//
//  TsDemuxer.m
//  MPlaYer
//
//  Created by wuwenhao on 2020/8/20.
//  Copyright © 2020 MOSI. All rights reserved.
//

#import "TsDemuxer.h"
#import "Demuxer.h"
#import "LocalCacheHandler.h"
#import "Downloader.h"
#import "MOSISYstemEx.h"

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

    MOSIHTTPSessionManager *session  = [MOSIHTTPSessionManager manager];
    NSURLRequest *request = [NSURLRequest requestWithURL:tsURL];
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request
                                                                    progress: nil
                                                                 destination:destinationPathHandler
                                                           completionHandler:completionHandler];
    [downloadTask resume];
}

+ (void) demuxLocalTsFiles:(NSArray<NSURL *> *) tsURLs handler:(void (^)(NSURL *, NSURL *, Error *)) handler {
    [Demuxer demuxLocalTsFiles:tsURLs dir:[LocalCacheHandler mosiLinkCacheTsDir] handler:^(NSURL * _Nonnull audioURL, NSURL * _Nonnull videoURL, NSError * _Nonnull error) {
        if (handler) {
            handler(audioURL, videoURL, [Error errorFromNSError:error]);
        }
    }];
}
@end
