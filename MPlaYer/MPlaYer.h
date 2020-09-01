//
//  MPlaYer.h
//  MPlaYer
//
//  Created by 吴文豪 on 2020/8/17.
//  Copyright © 2020 吴文豪. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPlaYer : NSObject
- (void) fetchLiveStream:(NSURL *)url
                 handler:(void (^)(UInt32 channelsPerFrame, UInt32 bytesPerFrame, UInt32 frameCount, void * _Nonnull frames))handler;
@end
