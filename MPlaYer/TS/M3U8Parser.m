//
//  M3U8Parser.m
//  MPlaYer
//
//  Created by 吴文豪 on 2020/8/20.
//  Copyright © 2020 吴文豪. All rights reserved.
//

#import "M3U8Parser.h"
#import "Downloader.h"
#import "SYstemEx.h"
#import "LocalCacheHandler.h"

@implementation M3U8Parser
+ (void)m3u8Parser:(NSURL *)m3u8URL handler:(void (^)(NSArray<NSURL *> * __nullable, Error * _Nonnull))handler {

    if (![m3u8URL isAvalidM3U8URL]) {
        if (handler) handler(nil, [Error paramError:@"m3u8 路径不合法（不包含\".mu38\"字符串）"]);
    }

    // 临时路径，解析完后接口内部清理
    NSString *tempDir = [LocalCacheHandler uniqueTempTsPath];
    NSURL *tempURL = [NSURL fileURLWithPath:[tempDir stringByAppendingPathComponent:@"m3u8.txt"]];

    NSURL * (^destinationPathHandler)(NSURL * _Nonnull, NSURLResponse * _Nonnull) =
    ^ (NSURL *targetPath, NSURLResponse *response) {
        return tempURL;
    };

    void (^completionHandler)(NSURLResponse * _Nonnull, NSURL * _Nonnull, NSError * _Nonnull) =
    ^ (NSURLResponse *response, NSURL *filePath, NSError *error) {
        if (!error &&
            ((NSHTTPURLResponse *)response).statusCode == 200 &&
            [[NSFileManager defaultManager] fileExistsAtPath:tempURL.path]) {

            // 路径已经被填充文件
            [self parseM3U8:filePath handler:handler];
        }
        else {

            if (handler) handler(nil, [Error errorFromNSError:error]);
        }
        // 删除临时路径及文件
        [LocalCacheHandler cleanPath:tempDir];
    };

    AFHTTPSessionManager *session  = [AFHTTPSessionManager manager];
    NSURLRequest *request = [NSURLRequest requestWithURL:m3u8URL];
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request
                                                                    progress: nil
                                                                 destination:destinationPathHandler
                                                           completionHandler:completionHandler];
    [downloadTask resume];
}
#pragma mark - private methods 
/// 从 m3u8 文件中解析出 .ts 路径
+ (void) parseM3U8:(NSURL *)url handler: (void (^)(NSArray<NSURL *> *, Error *))handler {

    NSError *err = nil;
    NSString *content = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&err];

    if (err && handler) handler(nil, [Error errorFromNSError:err]);

    NSArray<NSString *> *arr = [content componentsSeparatedByString:@"\r\n"];
    NSMutableArray<NSURL *> *tsArrM = [NSMutableArray new];
    for (int i = 0; i < arr.count ; i++) {
        if ([arr[i] hasSuffix:@".ts"] && [NSURL fileURLWithPath:arr[i]]) {
            [tsArrM addObject:[NSURL URLWithString:arr[i]]];
        }
    }

    if (handler) handler(tsArrM.copy, [Error success]);
}
@end
