//
//  SETextView.m
//  SECoreTextView
//
//  Created by kishikawa katsumi on 2013/04/19.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import "SETextLayout.h"
#import "SELineLayout.h"
#import "SETextSelection.h"
#import "SELinkText.h"
#import "SETextGeometry.h"

@interface SETextLayout () {
    CTFramesetterRef _framesetter;
    CTFrameRef _frame;
}

@end

@implementation SETextLayout

- (id)initWithAttributedString:(NSAttributedString *)attributedString
{
    self = [super init];
    if (self) {
        self.attributedString = [attributedString copy];
    }
    return self;
}

- (void)dealloc
{
    if (_framesetter) {
        CFRelease(_framesetter);
    }
    if (_frame) {
        CFRelease(_frame);
    }
}

+ (CGRect)frameRectWithAttributtedString:(NSAttributedString *)attributedString
                          constraintSize:(CGSize)constraintSize
                             edgePadding:(NSEdgeInsets)edgePadding
                             lineSpacing:(CGFloat)lineSpacing
{
    SETextLayout *textLayout = [[SETextLayout alloc] initWithAttributedString:attributedString];
    
    CGRect bounds = CGRectZero;
    bounds.size = constraintSize;
    
    textLayout.bounds = bounds;
    textLayout.edgePadding = edgePadding;
    textLayout.lineSpacing = lineSpacing;
    
    [textLayout setParagraphStyle];
    
    [textLayout createFramesetter];
    [textLayout createFrame];
    
    return textLayout.frameRect;
}

#pragma mark -

- (void)createFramesetter
{
    if (_framesetter) {
        CFRelease(_framesetter);
    }
    
    CFAttributedStringRef attributedString = (__bridge CFAttributedStringRef)self.attributedString;
    if (attributedString) {
        _framesetter = CTFramesetterCreateWithAttributedString(attributedString);
    } else {
        attributedString = CFAttributedStringCreate(NULL, CFSTR(""), NULL);
        _framesetter = CTFramesetterCreateWithAttributedString(attributedString);
        CFRelease(attributedString);
    }
}

- (void)createFrame
{
    if (_frame) {
        CFRelease(_frame);
    }
    
    CGRect frameRect = _bounds;
    NSEdgeInsets padding = _edgePadding;
	frameRect.size.width -= (padding.left + padding.right);
	frameRect.origin.x += padding.left;
#if TARGET_OS_IPHONE
	frameRect.origin.y -= padding.top;
#else
	frameRect.origin.y -= (padding.top + padding.bottom);
#endif
    
	CGSize frameSize = CTFramesetterSuggestFrameSizeWithConstraints(_framesetter,
                                                                    CFRangeMake(0, _attributedString.length),
                                                                    NULL,
                                                                    CGSizeMake(frameRect.size.width, CGFLOAT_MAX),
                                                                    NULL);
	frameRect.origin.y = CGRectGetMaxY(frameRect) - frameSize.height;
    frameRect.size = CGSizeMake(frameSize.width, frameSize.height + padding.bottom);
    _frameRect = frameRect;
    
#if TARGET_OS_IPHONE
    CGRect drawingFrameRect = _frameRect;
    drawingFrameRect.origin.y = padding.top;
    _frameRect = drawingFrameRect;
#endif
	
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddRect(path, NULL, frameRect);
	_frame = CTFramesetterCreateFrame(_framesetter, CFRangeMake(0, 0), path, NULL);
	CGPathRelease(path);
}

- (void)detectLinks
{
    NSMutableArray *links = [[NSMutableArray alloc] init];
    
    NSUInteger length = self.attributedString.length;
    [self.attributedString enumerateAttribute:NSLinkAttributeName
                                      inRange:NSMakeRange(0, length)
                                      options:0
                                   usingBlock:^(id value, NSRange range, BOOL *stop)
     {
         if (value) {
             NSString *linkText = [self.attributedString.string substringWithRange:range];
             SELinkText *link = [[SELinkText alloc] initWithText:linkText object:value range:range];
             [links addObject:link];
         }
     }];
    
    _links = [links copy];
}

- (void)calculateLines
{
    CFArrayRef lines = CTFrameGetLines(_frame);
    CFIndex lineCount = CFArrayGetCount(lines);
    CGPoint lineOrigins[lineCount];
    CTFrameGetLineOrigins(_frame, CFRangeMake(0, 0), lineOrigins);
    
    NSMutableArray *lineLayouts = [[NSMutableArray alloc] initWithCapacity:lineCount];
    for (NSInteger index = 0; index < lineCount; index++) {
        CGPoint origin = lineOrigins[index];
        CTLineRef line = CFArrayGetValueAtIndex(lines, index);
        
        CGFloat ascent;
        CGFloat descent;
        CGFloat leading;
        CGFloat width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        
        SELineMetrics metrics;
        metrics.ascent = ascent;
        metrics.descent = descent;
        metrics.leading = leading;
        metrics.width = width;
        metrics.trailingWhitespaceWidth = CTLineGetTrailingWhitespaceWidth(line);
        
        CGRect lineRect = CGRectMake(origin.x,
                                     ceilf(origin.y - descent),
                                     width,
                                     ceilf(ascent + descent));
        lineRect.origin.x += _frameRect.origin.x;
        
#if TARGET_OS_IPHONE
        lineRect.origin.y = _frameRect.size.height - CGRectGetMaxY(lineRect);
#else
        lineRect.origin.y += _frameRect.origin.y;
#endif
        
        SELineLayout *lineLayout = [[SELineLayout alloc] initWithLine:line index:index rect:lineRect metrics:metrics];
        
        for (SELinkText *link in self.links) {
            CGRect linkRect = [lineLayout rectOfStringWithRange:link.range];
            if (!CGRectIsEmpty(linkRect)) {
                SETextGeometry *geometry = [[SETextGeometry alloc] initWithRect:linkRect lineNumber:index];
                [link addLinkGeometry:geometry];
                
                [lineLayout addLink:link];
            }
        }
        
        [lineLayouts addObject:lineLayout];
    }
    
    _lineLayouts = [lineLayouts copy];
}

- (void)update
{
    [self setParagraphStyle];
    
    [self createFramesetter];
    [self createFrame];
    
    [self detectLinks];
    
    [self calculateLines];
}

- (void)drawFrameInContext:(CGContextRef)context
{
	CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	CTFrameDraw(_frame, context);
}

- (void)drawInContext:(CGContextRef)context
{
    [self drawFrameInContext:context];    
}

#pragma mark -

- (CFIndex)stringIndexForPosition:(CGPoint)point
{
    for (SELineLayout *lineLayout in self.lineLayouts) {
        if ([lineLayout containsPoint:point]) {
            CFIndex index = [lineLayout stringIndexForPosition:point];
            
            if (index != kCFNotFound) {
                return index;
            }
        }
    }
    
    return kCFNotFound;
}

- (void)setSelectionStartWithPoint:(CGPoint)point;
{
    CFIndex index = [self stringIndexForPosition:point];
    if (index != kCFNotFound) {
        self.textSelection = [[SETextSelection alloc] initWithIndex:index];
    }
}

- (void)setSelectionEndWithPoint:(CGPoint)point;
{
    CFIndex index = [self stringIndexForPosition:point];
    if (index != kCFNotFound) {
        [self.textSelection setSelectionEndAtIndex:index];
    }
}

- (void)setSelectionWithPoint:(CGPoint)point
{
    CFIndex index = [self stringIndexForPosition:point];
    if (index == kCFNotFound) {
        return;
    }
    
    CFStringRef string = (__bridge CFStringRef)self.attributedString.string;
    CFRange range = CFRangeMake(0, CFStringGetLength(string));
    CFStringTokenizerRef tokenizer = CFStringTokenizerCreate(
                                                             NULL,
                                                             string,
                                                             range,
                                                             kCFStringTokenizerUnitWordBoundary,
                                                             NULL);
    CFStringTokenizerTokenType tokenType = CFStringTokenizerGoToTokenAtIndex(tokenizer, 0);
    while (tokenType != kCFStringTokenizerTokenNone || range.location + range.length < CFStringGetLength(string)) {
        range = CFStringTokenizerGetCurrentTokenRange(tokenizer);
        CFIndex first = range.location;
        CFIndex second = range.location + range.length;
        if (first != kCFNotFound && first <= index && index <= second) {
            self.textSelection = [[SETextSelection alloc] initWithIndex:range.location];
            [self.textSelection setSelectionEndAtIndex:range.location + range.length];
        }
        
        tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer);
    }
    CFRelease(tokenizer);
}

- (void)setSelectionWithFirstPoint:(CGPoint)firstPoint secondPoint:(CGPoint)secondPoint
{
    CFIndex firstIndex = [self stringIndexForPosition:firstPoint];
    if (firstIndex == kCFNotFound) {
        firstIndex = 0;
    }
    CFIndex secondIndex = [self stringIndexForPosition:secondPoint];
    if (secondIndex == kCFNotFound) {
        secondIndex = self.attributedString.length - firstIndex;
    }
    self.textSelection = [[SETextSelection alloc] initWithIndex:firstIndex];
    [self.textSelection setSelectionEndAtIndex:secondIndex];
}

#pragma mark -

- (void)setParagraphStyle
{
    NSTextAlignment textAlignment = _textAlignment;
    CGFloat lineSpacing = _lineSpacing;
    CGFloat lineHeight = _lineHeight;
    CGFloat paragraphSpacing = _paragraphSpacing;
    
    CTParagraphStyleSetting setting[] = {
        { kCTParagraphStyleSpecifierAlignment, sizeof(textAlignment), &textAlignment},
        { kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(lineHeight), &lineHeight },
        { kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(lineHeight), &lineHeight },
        { kCTParagraphStyleSpecifierLineSpacing, sizeof(lineSpacing), &lineSpacing },
        { kCTParagraphStyleSpecifierMinimumLineSpacing, sizeof(lineSpacing), &lineSpacing },
        { kCTParagraphStyleSpecifierMaximumLineSpacing, sizeof(lineSpacing), &lineSpacing },
        { kCTParagraphStyleSpecifierParagraphSpacing, sizeof(paragraphSpacing), &paragraphSpacing }
    };
    
    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(setting, sizeof(setting) / sizeof(CTParagraphStyleSetting));
    
    CFIndex length = _attributedString.length;
    NSMutableAttributedString *attributedString = [_attributedString mutableCopy];
    [attributedString addAttributes:@{(id)kCTParagraphStyleAttributeName: (__bridge id)paragraphStyle} range:NSMakeRange(0, length)];
    CFRelease(paragraphStyle);
    
    self.attributedString = attributedString;
}

@end
