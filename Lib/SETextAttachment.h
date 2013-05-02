//
//  SETextAttachment.h
//  SECoreTextView-iOS
//
//  Created by kishikawa katsumi on 2013/04/26.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>

#if !TARGET_OS_IPHONE
enum {
	kCTRunDelegateVersion1 = 1,
	kCTRunDelegateCurrentVersion = kCTRunDelegateVersion1
};

typedef void (*CTRunDelegateDeallocateCallback) ( void* refCon );
typedef CGFloat (*CTRunDelegateGetAscentCallback) ( void* refCon );
typedef CGFloat (*CTRunDelegateGetDescentCallback) ( void* refCon );
typedef CGFloat (*CTRunDelegateGetWidthCallback) ( void* refCon );

typedef struct {
	CFIndex							version;
	CTRunDelegateDeallocateCallback	dealloc;
	CTRunDelegateGetAscentCallback	getAscent;
	CTRunDelegateGetDescentCallback	getDescent;
	CTRunDelegateGetWidthCallback	getWidth;
} CTRunDelegateCallbacks;

typedef const struct __CTRunDelegate * CTRunDelegateRef;
CTRunDelegateRef CTRunDelegateCreate(const CTRunDelegateCallbacks* callbacks,
                                     void* refCon );
#endif

@interface SETextAttachment : NSObject

@property (strong, nonatomic, readonly) id object;
@property (assign, nonatomic, readonly) CGSize size;
@property (assign, nonatomic, readonly) NSRange range;

@property (assign, nonatomic, readonly) CTRunDelegateCallbacks callbacks;

- (id)initWithObject:(id)object size:(CGSize)size range:(NSRange)range;

@end
