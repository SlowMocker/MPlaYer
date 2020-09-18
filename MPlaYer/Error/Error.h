//
//  Error.h
//  MPlaYer
//
//  Created by wuwenhao on 2020/8/18.
//  Copyright © 2020 MOSI. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define MPLAYER_ERROR_CODE_SUCCESS @"MPlaYer_Error_0"
#define MPLAYER_ERROR_CODE_PARAM_ERROR @"MPlaYer_Error_1"
#define MPLAYER_ERROR_CODE_DEMUX_ERROR @"MPlaYer_Error_2"

@interface Error : NSObject
@property (nonatomic , copy) NSString *code;
@property (nonatomic , copy) NSString *localizedDescription;

- (BOOL) isSuccess;

+ (id) errorFromNSError:(NSError *)error;

+ (id) success;
+ (id) paramError:(NSString *)desc;
+ (id) demuxError:(NSString *)desc;
@end

NS_ASSUME_NONNULL_END
