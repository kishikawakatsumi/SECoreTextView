//
//  SEImageCache.h
//  SECoreTextView
//
//  Created by kishikawa katsumi on 2013/04/13.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import "SECompatibility.h"

typedef void(^SEImageDownloadCompletionBlock)(NSImage *image, NSError *error);

@interface SEImageCache : NSObject

+ (SEImageCache *)sharedInstance;

- (NSImage *)imageForURL:(NSURL *)imageURL completionBlock:(SEImageDownloadCompletionBlock)block;
- (NSImage *)imageForURL:(NSURL *)imageURL defaultImage:(NSImage *)defaultImage completionBlock:(SEImageDownloadCompletionBlock)block;

@end
