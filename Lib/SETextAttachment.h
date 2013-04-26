//
//  SETextAttachment.h
//  SECoreTextView-iOS
//
//  Created by kishikawa katsumi on 2013/04/26.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>

@interface SETextAttachment : NSObject

@property (strong, nonatomic, readonly) id object;
@property (assign, nonatomic, readonly) CGSize size;
@property (assign, nonatomic, readonly) NSRange range;

@property (assign, nonatomic, readonly) CTRunDelegateCallbacks callbacks;

- (id)initWithObject:(id)object size:(CGSize)size range:(NSRange)range;

@end
#endif
