//
//  SYstemEx.m
//  MPlaYer
//
//  Created by wuwenhao on 2020/8/20.
//  Copyright © 2020 MOSI. All rights reserved.
//

#import "MOSISYstemEx.h"

@implementation MOSISYstemEx

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
