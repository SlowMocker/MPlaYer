//
//  TSEngine.h
//  MPlaYer
//
//  Created by 吴文豪 on 2020/8/18.
//  Copyright © 2020 吴文豪. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class TsHandler;
@protocol TsHandlerProtocol <NSObject>

- (void) tsHandler:(TsHandler *)engine didReceiveNewAudioPath:(NSURL *)url;

@end

@interface TsHandler : NSObject
// 每次设置都会自动 flush
@property (nonatomic , strong) NSURL *m3u8URL;

@property (nonatomic , weak) id<TsHandlerProtocol> delegate;

- (void) start;

@end

NS_ASSUME_NONNULL_END
