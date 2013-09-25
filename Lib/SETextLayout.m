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

- (id)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithAttributedString:(NSAttributedString *)attributedString
{
    self = [super init];
    if (self) {
        [self commonInit];
        self.attributedString = [attributedString copy];
    }
    
    return self;
}

- (void)commonInit
{
    self.markedTextRange = NSMakeRange(NSNotFound, 0);
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
{
    SETextLayout *textLayout = [[SETextLayout alloc] initWithAttributedString:attributedString];
    
    CGRect bounds = CGRectZero;
    bounds.size = constraintSize;
    
    textLayout.bounds = bounds;
    
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
	CGSize frameSize = CTFramesetterSuggestFrameSizeWithConstraints(_framesetter,
                                                                    CFRangeMake(0, _attributedString.length),
                                                                    NULL,
                                                                    CGSizeMake(frameRect.size.width, CGFLOAT_MAX),
                                                                    NULL);
    if (self.isEditing) {
        frameSize.height += [[UIFont systemFontOfSize:[UIFont labelFontSize]] leading]; // Workaround
    }
	frameRect.origin.y = CGRectGetMaxY(frameRect) - frameSize.height;
    frameRect.size = frameSize;
	
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathAddRect(path, NULL, frameRect);
	_frame = CTFramesetterCreateFrame(_framesetter, CFRangeMake(0, 0), path, NULL);
	CGPathRelease(path);
    
    _frameRect = frameRect;
#if TARGET_OS_IPHONE
    _frameRect.origin.y = 0.0f;
#endif
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
                                     origin.y - descent,
                                     width,
                                     ascent + descent);
        lineRect.origin.x += _frameRect.origin.x;
        
#if TARGET_OS_IPHONE
        lineRect.origin.y = CGRectGetHeight(_frameRect) - CGRectGetMaxY(lineRect);
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
    [self createFramesetter];
    [self createFrame];
    
    [self detectLinks];
    
    [self calculateLines];
}

- (void)drawFrameInContext:(CGContextRef)context
{
#if TARGET_OS_IPHONE
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
#endif

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

- (CFIndex)stringIndexForClosestPosition:(CGPoint)point
{
    CFIndex lineNumber = 0;
    for (SELineLayout *lineLayout in self.lineLayouts) {
        if ([lineLayout containsPoint:point]) {
            CFIndex index = [lineLayout stringIndexForPosition:point];
            if (index != kCFNotFound) {
                return index;
            }
        }
        
#if TARGET_OS_IPHONE
        if (lineNumber == 0 && point.y < CGRectGetMinY(lineLayout.rect)) {
            return 0;
        }
        
        if (lineNumber == self.lineLayouts.count - 1 && point.y > CGRectGetMaxY(lineLayout.rect) - lineLayout.metrics.leading) {
            return [lineLayout stringIndexForPosition:CGPointMake(CGRectGetMaxX(lineLayout.rect), CGRectGetMinY(lineLayout.rect))];
        }
        
        if (point.y > CGRectGetMinY(lineLayout.rect) && point.y < CGRectGetMaxY(lineLayout.rect) - lineLayout.metrics.leading) {
            return [lineLayout stringIndexForPosition:CGPointMake(CGRectGetMaxX(lineLayout.rect), CGRectGetMinY(lineLayout.rect))];
        }
#else
        if (lineNumber == 0 && point.y > CGRectGetMaxY(lineLayout.rect)) {
            return 0;
        }
        
        if (lineNumber == self.lineLayouts.count - 1 && point.y < CGRectGetMinY(lineLayout.rect) - lineLayout.metrics.leading) {
            return [lineLayout stringIndexForPosition:CGPointMake(CGRectGetMaxX(lineLayout.rect), CGRectGetMaxY(lineLayout.rect))];
        }
        
        if (point.y < CGRectGetMaxY(lineLayout.rect) && point.y > CGRectGetMinY(lineLayout.rect) - lineLayout.metrics.leading) {
            return [lineLayout stringIndexForPosition:CGPointMake(CGRectGetMaxX(lineLayout.rect), CGRectGetMaxY(lineLayout.rect))];
        }
#endif
        
        lineNumber++;
    }
    
    return kCFNotFound;
}

- (CGRect)rectOfStringForIndex:(CFIndex)index;
{
    CGRect rect = CGRectZero;
    
    if (index != kCFNotFound) {
        for (SELineLayout *lineLayout in self.lineLayouts) {
            NSRange stringRange = lineLayout.stringRange;
            
            if (index >= stringRange.location && index <= stringRange.location + stringRange.length) {
                CTLineRef line = lineLayout.line;
                CGFloat offset = CTLineGetOffsetForStringIndex(line, index, NULL);
                
                CGFloat width = offset;
                if (index > 1) {
                    width = offset - CTLineGetOffsetForStringIndex(line, index - 1, NULL);
                }
                
                rect = lineLayout.rect;
                rect.origin.x += offset - width;
                rect.size.width = width;
                
                break;
            }
        }
    }
    
    return rect;
}

- (CGRect)rectOfStringForLastLine
{
    SELineLayout *lineLayout = self.lineLayouts.lastObject;
    NSRange stringRange = lineLayout.stringRange;
    
    CTLineRef line = lineLayout.line;
    CGFloat offset = CTLineGetOffsetForStringIndex(line, stringRange.location, NULL);
    
    CGRect rect = CGRectZero;
    rect = lineLayout.rect;
    rect.origin.x += offset;
    
    return rect;
}

- (void)setSelectionStartWithPoint:(CGPoint)point;
{
    CFIndex index = [self stringIndexForPosition:point];
    if (index != kCFNotFound) {
        self.textSelection = [[SETextSelection alloc] initWithIndex:index];
    } else {
        self.textSelection = nil;
    }
}

- (void)setSelectionEndWithPoint:(CGPoint)point;
{
    CFIndex index = [self stringIndexForClosestPosition:point];
    if (index != kCFNotFound) {
        [self.textSelection setSelectionEndAtIndex:index];
    }
}

- (void)setSelectionEndWithClosestPoint:(CGPoint)point;
{
    CFIndex index = [self stringIndexForClosestPosition:point];
    [self.textSelection setSelectionEndAtIndex:index];
}

- (void)setSelectionStartWithFirstPoint:(CGPoint)firstPoint
{
    CFIndex start = [self stringIndexForClosestPosition:firstPoint];
    CFIndex end = NSMaxRange(self.textSelection.selectedRange);
    
    if (start != kCFNotFound) {
        if (start < end) {
            self.textSelection = [[SETextSelection alloc] initWithIndex:start];
        } else {
            end = start;
        }
    }
    
    [self.textSelection setSelectionEndAtIndex:end];
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
    while (tokenType != kCFStringTokenizerTokenNone) {
        range = CFStringTokenizerGetCurrentTokenRange(tokenizer);
        CFIndex first = range.location;
        CFIndex second = range.location + range.length;
        if (first != kCFNotFound && first <= index && index <= second) {
            self.textSelection = [[SETextSelection alloc] initWithIndex:range.location];
            [self.textSelection setSelectionEndAtIndex:range.location + range.length];
            break;
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

- (void)selectAll
{
    self.textSelection = [[SETextSelection alloc] initWithIndex:0];
    [self.textSelection setSelectionEndAtIndex:self.attributedString.length];
}

- (void)clearSelection
{
    self.textSelection = nil;
}

@end
