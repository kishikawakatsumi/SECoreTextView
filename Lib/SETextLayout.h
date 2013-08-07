//
//  SETextView.h
//  SECoreTextView
//
//  Created by kishikawa katsumi on 2013/04/19.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import "SECompatibility.h"

@class SETextSelection, SELinkText;

@interface SETextLayout : NSObject

@property (copy, nonatomic) NSAttributedString *attributedString;

@property (assign, nonatomic) CGRect bounds;

@property (assign, nonatomic, readonly) CGRect frameRect;
@property (strong, nonatomic, readonly) NSArray *lineLayouts;

@property (strong, nonatomic) SETextSelection *textSelection;
@property (strong, nonatomic, readonly) NSArray *links;

- (id)initWithAttributedString:(NSAttributedString *)attributedString;
- (void)update;
- (void)drawInContext:(CGContextRef)context;

- (CFIndex)stringIndexForPosition:(CGPoint)point;

- (void)setSelectionStartWithPoint:(CGPoint)point;
- (void)setSelectionEndWithPoint:(CGPoint)point;
- (void)setSelectionEndWithNearestPoint:(CGPoint)point;
- (void)setSelectionStartWithFirstPoint:(CGPoint)firstPoint;

- (void)setSelectionWithPoint:(CGPoint)point;
- (void)setSelectionWithFirstPoint:(CGPoint)firstPoint secondPoint:(CGPoint)secondPoint;

- (void)selectAll;
- (void)clearSelection;

+ (CGRect)frameRectWithAttributtedString:(NSAttributedString *)attributedString
                          constraintSize:(CGSize)constraintSize;

@end
