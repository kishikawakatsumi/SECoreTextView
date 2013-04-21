//
//  SEImageCache.m
//  SECoreTextView
//
//  Created by kishikawa katsumi on 2013/04/13.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import "SEImageCache.h"

@interface SEImageCache ()

@property (strong, nonatomic) NSCache *cache;
@property (strong, nonatomic) NSOperationQueue *queue;

@end

@implementation SEImageCache

+ (SEImageCache *)sharedInstance
{
    static SEImageCache *sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SEImageCache alloc] init];
    });
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _cache = [[NSCache alloc] init];
        _queue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (NSImage *)imageForURL:(NSURL *)imageURL completionBlock:(SEImageDownloadCompletionBlock)block
{
    return [self imageForURL:imageURL defaultImage:nil completionBlock:block];
}

- (NSImage *)imageForURL:(NSURL *)imageURL defaultImage:(NSImage *)defaultImage completionBlock:(SEImageDownloadCompletionBlock)block
{
    NSString *key = [SEImageCache MD5HexDigest:imageURL.absoluteString];
    NSImage *cachedImage = [self.cache objectForKey:key];
    if (cachedImage) {
        return cachedImage;
    }
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:imageURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    [[self class] sendAsynchronousRequest:request queue:self.queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         if (!error) {
             NSImage *image = [[NSImage alloc] initWithData:data];
             if (image) {
                 [self.cache setObject:image forKey:key];
                 
                 dispatch_async(dispatch_get_main_queue(), ^
                                {
                                    if (block) {
                                        block(image, nil);
                                    }
                                });
             } else {
                 NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:nil];
                 dispatch_async(dispatch_get_main_queue(), ^
                                {
                                    if (block) {
                                        block(nil, error);
                                    }
                                });
             }
         } else {
             
             dispatch_async(dispatch_get_main_queue(), ^
                            {
                                if (block) {
                                    block(nil, error);
                                }
                            });
         }
     }];
    
    return defaultImage;
}

+ (void)sendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue completionHandler:(void (^)(NSURLResponse *, NSData *, NSError *))handler
{
    if ([[NSThread currentThread] isMainThread]) {
        [queue addOperationWithBlock:^{
            NSURLResponse *response = nil;
            NSError *error = nil;
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            if (handler) {
                handler(response, data, error);
            }
        }];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self sendAsynchronousRequest:request queue:queue completionHandler:handler];
        });
    }
}

+ (NSString *)MD5HexDigest:(NSString *)input
{
    const char *str = [input UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), result);
    
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x",result[i]];
    }
    return ret;
}

@end
