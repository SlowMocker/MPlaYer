//
//  Error.m
//  MPlaYer
//
//  Created by 吴文豪 on 2020/8/18.
//  Copyright © 2020 吴文豪. All rights reserved.
//

#import "Error.h"

@implementation Error

- (BOOL) isSuccess {
    if ([@"MPlaYer_Error_0" isEqualToString:self.code]) {
        return YES;
    }
    return NO;
}

+ (id) errorFromNSError:(NSError *)err {
    if (!err) {
        return nil;
    }
    Error *error = [[Error alloc]init];
    error.code = [NSString stringWithFormat:@"MPlaYer_Error_%ld", err.code];
    error.localizedDescription = err.localizedDescription;
    return error;
}

+ (id) success {
    Error *error = [[Error alloc]init];
    error.code = MPLAYER_ERROR_CODE_SUCCESS;
    error.localizedDescription = @"SUCCESS";
    return error;
}

+ (id) paramError:(NSString *)desc {
    Error *error = [[Error alloc]init];
    error.code = MPLAYER_ERROR_CODE_PARAM_ERROR;
    error.localizedDescription = desc;
    return error;
}

+ (id) demuxError:(NSString *)desc {
    Error *error = [[Error alloc]init];
    error.code = MPLAYER_ERROR_CODE_DEMUX_ERROR;
    error.localizedDescription = desc;
    return error;
}

@end
