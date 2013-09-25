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

typedef void (*CTRunDelegateDeallocateCallback) (void *refCon);
typedef CGFloat (*CTRunDelegateGetAscentCallback) (void *refCon);
typedef CGFloat (*CTRunDelegateGetDescentCallback) (void *refCon);
typedef CGFloat (*CTRunDelegateGetWidthCallback) (void *refCon);

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
void* CTRunDelegateGetRefCon(
                             CTRunDelegateRef runDelegate );
#endif

@interface SETextAttachment : NSObject

@property (nonatomic, readonly) id object;
@property (nonatomic, readonly) CGSize size;
@property (nonatomic, readonly) NSRange range;

@property (nonatomic, readonly) CTRunDelegateCallbacks callbacks;

@property (nonatomic) NSAttributedString *originalAttributedString;
@property (nonatomic) NSString *replacedString;

- (id)initWithObject:(id)object size:(CGSize)size range:(NSRange)range;

@end
