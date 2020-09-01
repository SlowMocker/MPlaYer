//
//  SYstemEx.m
//  MPlaYer
//
//  Created by 吴文豪 on 2020/8/20.
//  Copyright © 2020 吴文豪. All rights reserved.
//

#import "SYstemEx.h"

@implementation SYstemEx

@end

@implementation NSURL (Ex)

- (BOOL) isAvalidM3U8URL {
    if ([self.path.lowercaseString containsString:@".m3u8"] && [self.scheme.lowercaseString containsString:@"http"]) {
        return YES;
    }
    return NO;
}

- (BOOL) isAvalidTsNetURL {
    if ([self.path.lowercaseString containsString:@".ts"] && [self.scheme.lowercaseString containsString:@"http"]) {
        return YES;
    }
    return NO;
}

@end
