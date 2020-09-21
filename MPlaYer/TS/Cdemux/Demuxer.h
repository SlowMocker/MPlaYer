//
//  Demuxer.h
//  TsDemuxer
//
//  Created by iSmicro on 2020/9/21.
//  Copyright © 2020 iSmicro. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Demuxer : NSObject
+ (void) demuxLocalTsFiles:(NSArray<NSURL *> *) tsURLs dir:(NSString *)dir handler:(void (^)(NSURL *, NSURL *, NSError *)) handler;
@end

NS_ASSUME_NONNULL_END
