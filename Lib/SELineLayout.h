//
//  SELine.h
//  SECoreTextView
//
//  Created by kishikawa katsumi on 2013/04/20.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>

@class SELinkText;

typedef struct {
    CGFloat ascent;
    CGFloat descent;
    CGFloat width;
    CGFloat leading;
    double trailingWhitespaceWidth;
} SELineMetrics;

@interface SELineLayout : NSObject

@property (assign, nonatomic, readonly) CTLineRef line;
@property (assign, nonatomic, readonly) NSInteger index;
@property (assign, nonatomic, readonly) CGRect rect;
@property (assign, nonatomic, readonly) SELineMetrics metrics;

@property (assign, nonatomic, readonly) NSRange stringRange;

@property (strong, nonatomic, readonly) NSArray *links;
@property (assign, nonatomic, readonly) BOOL containsLink;
@property (assign, nonatomic, readonly) NSUInteger numberOfLinks;

- (id)initWithLine:(CTLineRef)line index:(NSInteger)index rect:(CGRect)rect metrics:(SELineMetrics)metrics;

- (BOOL)containsPoint:(CGPoint)point;
- (CFIndex)stringIndexForPosition:(CGPoint)point;

- (CGRect)rectOfStringWithRange:(NSRange)range;

- (void)addLink:(SELinkText *)link;
- (SELinkText *)linkAtPoint:(CGPoint)point;

@end
