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

@property (assign, nonatomic) NSTextAlignment textAlignment;
@property (assign, nonatomic) CGFloat lineSpacing;
@property (assign, nonatomic) CGFloat lineHeight;
@property (assign, nonatomic) CGFloat paragraphSpacing;

@property (assign, nonatomic) CGRect bounds;
@property (assign, nonatomic) NSEdgeInsets edgePadding;

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

- (void)setSelectionWithPoint:(CGPoint)point;
- (void)setSelectionWithFirstPoint:(CGPoint)firstPoint secondPoint:(CGPoint)secondPoint;

+ (CGRect)frameRectWithAttributtedString:(NSAttributedString *)attributedString
                          constraintSize:(CGSize)constraintSize
                             edgePadding:(NSEdgeInsets)edgePadding
                             lineSpacing:(CGFloat)lineSpacing;

@end
