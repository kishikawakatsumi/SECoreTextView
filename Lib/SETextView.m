//
//  SETextView.m
//  SECoreTextView
//
//  Created by kishikawa katsumi on 2013/04/20.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import "SETextView.h"
#import "SETextLayout.h"
#import "SELineLayout.h"
#import "SETextSelection.h"
#import "SETextMagnifierCaret.h"
#import "SESelectionGrabber.h"
#import "SELinkText.h"
#import "SETextGeometry.h"

typedef NS_ENUM(NSUInteger, SEMouseState) {
    SEMouseStateNone,
    SEMouseStateClicked,
    SEMouseStateDragging,
    SEMouseStateHover
};

@interface SETextView ()

@property (strong, nonatomic) SETextLayout *textLayout;

@property (assign, nonatomic) SEMouseState mouseState;
@property (assign, nonatomic) CGPoint clickPoint;
@property (assign, nonatomic) CGPoint mouseLocation;

@property (copy, nonatomic) NSAttributedString *attributedTextCopy;

#if TARGET_OS_IPHONE
@property (strong, nonatomic) SETextMagnifierCaret *magnifierCaret;
@property (strong, nonatomic) SESelectionGrabber *startGrabber;
@property (strong, nonatomic) SESelectionGrabber *endGrabber;
#endif

@end

@implementation SETextView

- (void)commonInit
{
    self.textLayout = [[SETextLayout alloc] init];
    self.textLayout.bounds = self.bounds;
    
    self.font = [NSFont systemFontOfSize:13.0f];
    self.textColor = [NSColor blackColor];
    self.highlightedTextColor = [NSColor whiteColor];
    
    self.selectedTextBackgroundColor = [NSColor selectedTextBackgroundColor];
    self.linkHighlightColor = [NSColor selectedTextBackgroundColor];
    self.linkRolloverEffectColor = [NSColor selectedMenuItemColor];
    
#if TARGET_OS_IPHONE
    self.selectionGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(selectionChanged:)];
    self.selectionGestureRecognizer.enabled = self.selectable;
    [self addGestureRecognizer:self.selectionGestureRecognizer];
#endif
}

- (void)awakeFromNib
{
    [self commonInit];
}

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame edgePadding:NSEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
}

- (id)initWithFrame:(CGRect)frame topPadding:(CGFloat)topPadding leftPadding:(CGFloat)leftPadding
{
    return [self initWithFrame:frame edgePadding:NSEdgeInsetsMake(topPadding, leftPadding, topPadding, leftPadding)];
}

- (id)initWithFrame:(CGRect)frame edgePadding:(NSEdgeInsets)edgePadding
{
    self = [super initWithFrame:frame];
    if (self) {
        self.edgePadding = edgePadding;
        [self commonInit];
    }
    
    return self;
}

#pragma mark -

+ (CGRect)frameRectWithAttributtedString:(NSAttributedString *)attributedString
                          constraintSize:(CGSize)constraintSize
{
    return [self frameRectWithAttributtedString:attributedString
                                 constraintSize:constraintSize
                                    edgePadding:NSEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
}

+ (CGRect)frameRectWithAttributtedString:(NSAttributedString *)attributedString
                          constraintSize:(CGSize)constraintSize
                             edgePadding:(NSEdgeInsets)edgePadding
{
    return [self frameRectWithAttributtedString:attributedString
                                 constraintSize:constraintSize
                                    edgePadding:edgePadding
                                    lineSpacing:0.0f];
}

+ (CGRect)frameRectWithAttributtedString:(NSAttributedString *)attributedString
                          constraintSize:(CGSize)constraintSize
                             lineSpacing:(CGFloat)lineSpacing
{
    return [self frameRectWithAttributtedString:attributedString
                                 constraintSize:constraintSize
                                    edgePadding:NSEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)
                                    lineSpacing:lineSpacing];
}

+ (CGRect)frameRectWithAttributtedString:(NSAttributedString *)attributedString
                          constraintSize:(CGSize)constraintSize
                             edgePadding:(NSEdgeInsets)edgePadding
                             lineSpacing:(CGFloat)lineSpacing
{
    return [self frameRectWithAttributtedString:attributedString
                                 constraintSize:constraintSize
                                           font:nil
                                    edgePadding:edgePadding
                                    lineSpacing:lineSpacing];
}

+ (CGRect)frameRectWithAttributtedString:(NSAttributedString *)attributedString
                          constraintSize:(CGSize)constraintSize
                                    font:(NSFont *)font
{
    return [self frameRectWithAttributtedString:attributedString
                                 constraintSize:constraintSize
                                           font:font
                                    edgePadding:NSEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
}

+ (CGRect)frameRectWithAttributtedString:(NSAttributedString *)attributedString
                          constraintSize:(CGSize)constraintSize
                                    font:(NSFont *)font
                             lineSpacing:(CGFloat)lineSpacing
{
    return [self frameRectWithAttributtedString:attributedString
                                 constraintSize:constraintSize
                                           font:font
                                    edgePadding:NSEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)
                                    lineSpacing:lineSpacing];
}

+ (CGRect)frameRectWithAttributtedString:(NSAttributedString *)attributedString
                          constraintSize:(CGSize)constraintSize
                                    font:(NSFont *)font
                             edgePadding:(NSEdgeInsets)edgePadding
{
    return [self frameRectWithAttributtedString:attributedString
                                 constraintSize:constraintSize
                                           font:font
                                    edgePadding:edgePadding
                                    lineSpacing:0.0f];
}

+ (CGRect)frameRectWithAttributtedString:(NSAttributedString *)attributedString
                          constraintSize:(CGSize)constraintSize
                                    font:(NSFont *)font
                             edgePadding:(NSEdgeInsets)edgePadding
                             lineSpacing:(CGFloat)lineSpacing
{
    if (font) {
        NSInteger length = attributedString.length;
        NSMutableAttributedString *mutableAttributedString = [attributedString mutableCopy];
        
        CFStringRef fontName = (__bridge CFStringRef)font.fontName;
        CGFloat fontSize = font.pointSize;
        CTFontRef ctfont = CTFontCreateWithName(fontName, fontSize, NULL);
        [mutableAttributedString addAttributes:@{(id)kCTFontAttributeName: (__bridge id)ctfont} range:NSMakeRange(0, length)];
        CFRelease(ctfont);
        
        attributedString = mutableAttributedString;
    }
    
    return [SETextLayout frameRectWithAttributtedString:attributedString
                                         constraintSize:constraintSize
                                            edgePadding:edgePadding
                                            lineSpacing:lineSpacing];
}

#pragma mark -

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self setNeedsDisplayInRect:self.bounds];
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    [self setNeedsDisplayInRect:self.bounds];
}

- (void)setSelectable:(BOOL)selectable
{
    _selectable = selectable;
    self.selectionGestureRecognizer.enabled = self.selectable;
}

- (void)setText:(NSString *)text
{
    _text = text;
    if (self.text) {
        self.attributedText = [[NSAttributedString alloc] initWithString:text];
    } else {
        self.attributedText = [[NSAttributedString alloc] initWithString:@""];
    }
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    _attributedText = [attributedText copy];
    [self setNeedsDisplayInRect:self.bounds];
}

- (void)setFont:(NSFont *)font
{
    _font = font;
    
    CFStringRef fontName = (__bridge CFStringRef)font.fontName;
    CGFloat fontSize = font.pointSize;
	CTFontRef ctfont = CTFontCreateWithName(fontName, fontSize, NULL);
    [self setAttributes:@{(id)kCTFontAttributeName: (__bridge id)ctfont}];
	CFRelease(ctfont);
}

- (void)setTextColor:(NSColor *)textColor
{
    _textColor = textColor;
    
    CGColorRef color = textColor.CGColor;    
    [self setAttributes:@{(id)kCTForegroundColorAttributeName: (__bridge id)color}];
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment
{
    self.textLayout.textAlignment = textAlignment;
}

- (NSTextAlignment)textAlignment
{
    return self.textLayout.textAlignment;
}

- (void)setLineSpacing:(CGFloat)lineSpacing
{
    self.textLayout.lineSpacing = lineSpacing;
}

- (CGFloat)lineSpacing
{
    return self.textLayout.lineSpacing;
}

- (void)setEdgePadding:(NSEdgeInsets)edgePadding
{
    self.textLayout.edgePadding = edgePadding;
}

- (NSEdgeInsets)edgePadding
{
    return self.textLayout.edgePadding;
}

- (CGRect)layoutFrame
{
    return self.textLayout.frameRect;
}

#pragma mark -

- (void)setAttributes:(NSDictionary *)attributes
{
    NSInteger length = self.attributedText.length;
    NSMutableAttributedString *attributedString = [self.attributedText mutableCopy];
    
    if (attributedString && attributes) {
        [attributedString addAttributes:attributes range:NSMakeRange(0, length)];
    }
    
    self.attributedText = attributedString;
}

#pragma mark -

- (void)clearSelection
{
    self.textLayout.textSelection = nil;
}

- (void)clickedOnLink:(SELinkText *)link
{
    if ([self.delegate respondsToSelector:@selector(textView:clickedOnLink:atIndex:)]) {
#if TARGET_OS_IPHONE
        [self.delegate textView:self clickedOnLink:link atIndex:[self stringIndexAtPoint:[self shiftedMouseLocation]]];
#else
        [self.delegate textView:self clickedOnLink:link atIndex:[self stringIndexAtPoint:[self shiftedMouseLocation]]];
#endif
    }
}

#pragma mark -

- (void)highlightSelection
{
    SETextSelection *textSelection = self.textLayout.textSelection;
    if (!textSelection) {
        return;
    }
    
    NSInteger counter = 0;
    CGRect selectionStartRect = CGRectZero;
    CGRect selectionEndRect = CGRectZero;
    
    for (SELineLayout *lineLayout in self.textLayout.lineLayouts) {
        CGRect selectionRect = [lineLayout rectOfStringWithRange:textSelection.selectedRange];
        if (!CGRectIsEmpty(selectionRect)) {
            [self.selectedTextBackgroundColor set];
            CGFloat lineSpacing = self.lineSpacing;
            selectionRect.origin.y -= lineSpacing;
            selectionRect.size.height += lineSpacing;
            NSRectFill(selectionRect);
            
            if (counter == 0) {
                selectionStartRect = selectionRect;
                selectionEndRect = selectionRect;
            } else {
                selectionEndRect = selectionRect;
            }
            
            counter++;
        }
    }
    
    textSelection.startRect = selectionStartRect;
    textSelection.endRect = selectionEndRect;
}

- (CFIndex)stringIndexAtPoint:(CGPoint)point
{
    for (SELineLayout *lineLayout in self.textLayout.lineLayouts) {
        if ([lineLayout containsPoint:point]) {
            CFIndex index = [lineLayout stringIndexForPosition:point];
            if (index != kCFNotFound) {
                return index;
            }
        }
    }
    
    return kCFNotFound;
}

- (SELinkText *)linkAtPoint:(CGPoint)point
{
    for (SELineLayout *lineLayout in self.textLayout.lineLayouts) {
        SELinkText *link = [lineLayout linkAtPoint:point];
        if (link) {
            return link;
        }
    }
    
    return nil;
}

- (void)enumerateLinksUsingBlock:(void (^)(SELinkText *link, BOOL *stop))block
{
    for (SELineLayout *lineLayout in self.textLayout.lineLayouts) {
        for (SELinkText *link in lineLayout.links) {
            BOOL flag = NO;
            block(link, &flag);
            if (flag) {
                break;
            }
        }
    }
}

- (void)updateCursorRectsInLinks
{
#if !TARGET_OS_IPHONE
    [self discardCursorRects];
    
    [self addCursorRect:self.textLayout.frameRect cursor:[NSCursor IBeamCursor]];
    
    if (self.mouseState == SEMouseStateHover) {
        [self enumerateLinksUsingBlock:^(SELinkText *link, BOOL *stop) {
            for (SETextGeometry *geometry in link.geometries) {
                [self addCursorRect:geometry.rect cursor:[NSCursor pointingHandCursor]];
            }
        }];
    }
#endif
}

- (void)updateTrackingAreasInLinks
{
#if !TARGET_OS_IPHONE
    NSArray *trackingAreas = self.trackingAreas;
    for (NSTrackingArea *trackingArea in trackingAreas) {
        [self removeTrackingArea:trackingArea];
    }
    
    [self enumerateLinksUsingBlock:^(SELinkText *link, BOOL *stop) {
        for (SETextGeometry *geometry in link.geometries) {
            NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:geometry.rect
                                                                        options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow
                                                                          owner:self
                                                                       userInfo:nil];
            [self addTrackingArea:trackingArea];
        }
    }];
#endif
}

- (void)_highlightLinks
{
    [self enumerateLinksUsingBlock:^(SELinkText *link, BOOL *stop) {
        for (SETextGeometry *geometry in link.geometries) {
            [self.linkHighlightColor set];
            CGRect linkRect = geometry.rect;
            
#if TARGET_OS_IPHONE
            UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:linkRect cornerRadius:3.0f];
#else
            NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:linkRect xRadius:3.0f yRadius:3.0f];
#endif
            [path fill];
        }
    }];
}

- (void)highlightClickedLink
{
    if (self.mouseState == SEMouseStateClicked) {
        SELinkText *link = [self linkAtPoint:self.mouseLocation];
        for (SETextGeometry *geometry in link.geometries) {
            [self.linkHighlightColor set];
            CGRect linkRect = geometry.rect;
            
#if TARGET_OS_IPHONE
            UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:linkRect cornerRadius:3.0f];
#else
            NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:linkRect xRadius:3.0f yRadius:3.0f];
#endif
            [path fill];
        }
    }
}

- (void)highlightRolloveredLink
{
#if !TARGET_OS_IPHONE
    if (self.mouseState == SEMouseStateHover) {
        SELinkText *link = [self linkAtPoint:self.mouseLocation];
        for (SETextGeometry *geometry in link.geometries) {
            [self.linkRolloverEffectColor set];
            CGRect linkRect = geometry.rect;
            linkRect.size.height = 1.0f;
            NSRectFill(linkRect);
        }
    }
#endif
}

#pragma mark -

- (void)drawRect:(CGRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
    self.textLayout.bounds = self.bounds;
    self.textLayout.attributedString = self.attributedText;
    
    [self.textLayout update];
    
    [self updateCursorRectsInLinks];
    [self updateTrackingAreasInLinks];
    
    [self highlightSelection];
    
    [self highlightRolloveredLink];
    [self highlightClickedLink];
    
#if TARGET_OS_IPHONE
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
#else
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
#endif
    
    [self.textLayout drawInContext:context];
}

#pragma mark -

#if TARGET_OS_IPHONE

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (CGRectContainsPoint(self.bounds, point)) {
        if (self.selectable) {
            return [super hitTest:point withEvent:event];
        } else {
            SELinkText *link = [self linkAtPoint:point];
            if (link) {
                return [super hitTest:point withEvent:event];
            }
        }
    }
    
    return nil;
}

- (void)showMagnifierCaretAtPoint:(CGPoint)point
{
    if (!self.magnifierCaret) {
        self.magnifierCaret = [[SETextMagnifierCaret alloc] initWithFrame:self.bounds];
    }
    
    [self.magnifierCaret showInView:self.window atPoint:[self convertPoint:point toView:nil]];
}

- (void)moveMagnifierCaretToPoint:(CGPoint)point
{
    [self.magnifierCaret moveToPoint:[self convertPoint:point toView:nil]];
}

- (void)hideMagnifierCaret
{
    [self.magnifierCaret hide];
    self.magnifierCaret = nil;
}

- (void)showSelectionGrabber
{
    SETextSelection *textSelection = self.textLayout.textSelection;
    if (textSelection) {
        CGRect startRect = textSelection.startRect;
        CGRect endRect = textSelection.endRect;
        
        if (!self.startGrabber) {
            self.startGrabber = [[SESelectionGrabber alloc] init];
            [self addSubview:self.startGrabber];
        }
        CGRect startFrame = startRect;
        startFrame.origin = CGPointMake(startFrame.origin.x - self.startGrabber.dotSize.width / 2, startFrame.origin.y - self.startGrabber.dotSize.height / 2);
        startFrame.size.width = self.startGrabber.frame.size.width;
        self.startGrabber.frame = startFrame;
        
        if (!self.endGrabber) {
            self.endGrabber = [[SESelectionGrabber alloc] init];
            [self addSubview:self.endGrabber];
        }
        CGRect endFrame = endRect;
        endFrame.origin = CGPointMake(CGRectGetMaxX(endRect) - self.endGrabber.dotSize.width / 2, CGRectGetMaxY(endRect) - self.endGrabber.dotSize.height / 2);
        endFrame.size.width = self.endGrabber.frame.size.width;
        self.endGrabber.frame = endFrame;
    }
}

- (void)hideSelectionGrabber
{
    [self.startGrabber removeFromSuperview];
    self.startGrabber = nil;
    
    [self.endGrabber removeFromSuperview];
    self.endGrabber = nil;
}

- (void)selectionChanged:(UILongPressGestureRecognizer *)gestureRecognizer
{
    self.mouseLocation = [gestureRecognizer locationInView:self];
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.mouseState = SEMouseStateDragging;
        CGPoint shiftedMouseLocation = [self shiftedMouseLocation];
        
        [self.textLayout setSelectionWithPoint:shiftedMouseLocation];
        
        [self showMagnifierCaretAtPoint:shiftedMouseLocation];
        [self hideSelectionGrabber];
    } else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        self.mouseState = SEMouseStateDragging;
        CGPoint shiftedMouseLocation = [self shiftedMouseLocation];
        
        [self.textLayout setSelectionWithPoint:shiftedMouseLocation];
        
        [self moveMagnifierCaretToPoint:shiftedMouseLocation];
        [self hideSelectionGrabber];
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded ||
               gestureRecognizer.state == UIGestureRecognizerStateCancelled ||
               gestureRecognizer.state == UIGestureRecognizerStateFailed) {
        [self hideMagnifierCaret];
        if (self.textLayout.textSelection) {
            [self showSelectionGrabber];
        }
    }
    [self setNeedsDisplay];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.anyObject;
    self.mouseLocation = [touch locationInView:self];
    self.mouseState = SEMouseStateNone;
    
    if (self.selectable) {
//        if (self.textLayout.textSelection) {
//            CGPoint shiftedMouseLocation = [self shiftedMouseLocation];
//            
//            SETextSelection *textSelection = self.textLayout.textSelection;
//            CGPoint startPoint = textSelection.startRect.origin;
//            CGPoint endPoint = CGPointMake(CGRectGetMaxX(textSelection.endRect), CGRectGetMaxY(textSelection.endRect));
//            
//            if (shiftedMouseLocation.x < startPoint.x) {
//                [self.textLayout setSelectionWithFirstPoint:shiftedMouseLocation secondPoint:endPoint];
//            } else {
//                [self.textLayout setSelectionWithFirstPoint:startPoint secondPoint:shiftedMouseLocation];
//            }
//        }
    } else {
        self.mouseState = SEMouseStateClicked;
    }
    
    [self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
//    if (self.selectable) {
//        if (self.textLayout.textSelection) {
//            CGPoint shiftedMouseLocation = [self shiftedMouseLocation];
//            
//            SETextSelection *textSelection = self.textLayout.textSelection;
//            CGPoint startPoint = textSelection.startRect.origin;
//            CGPoint endPoint = CGPointMake(CGRectGetMaxX(textSelection.endRect), CGRectGetMaxY(textSelection.endRect));
//            
//            if (shiftedMouseLocation.x < startPoint.x) {
//                [self.textLayout setSelectionWithFirstPoint:shiftedMouseLocation secondPoint:endPoint];
//            } else {
//                [self.textLayout setSelectionWithFirstPoint:startPoint secondPoint:shiftedMouseLocation];
//            }
//        }
//    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.anyObject;
    self.mouseLocation = [touch locationInView:self];
        
    self.mouseState = SEMouseStateNone;
    self.clickPoint = CGPointZero;
    
    if ([self isMouseLocationInTextFrame]) {
        SELinkText *link = [self linkAtPoint:self.mouseLocation];
        if (link) {
            [self clickedOnLink:link];
        }
    }
    
    if (!self.textLayout.textSelection) {
        [self hideSelectionGrabber];
    }
    
    [self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.mouseState = SEMouseStateNone;
    [self setNeedsDisplay];
}

#else
- (CGPoint)mouseLocationOnEvent:(NSEvent *)theEvent
{
    CGPoint locationInWindow = [theEvent locationInWindow];
    CGPoint location = [self convertPoint:locationInWindow fromView:nil];
    
    return location;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    self.mouseLocation = [self mouseLocationOnEvent:theEvent];
    
    if ([self isMouseLocationInTextFrame]) {
        self.mouseState = SEMouseStateClicked;
        [self.textLayout setSelectionStartWithPoint:[self shiftedMouseLocation]];
    } else {
        self.mouseState = SEMouseStateNone;
    }
    
    [self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    self.mouseLocation = [self mouseLocationOnEvent:theEvent];
    
    if ([self isMouseLocationInTextFrame]) {
        self.mouseState = SEMouseStateDragging;
        [self.textLayout setSelectionEndWithPoint:[self shiftedMouseLocation]];
    } else {
        self.mouseState = SEMouseStateNone;
    }
    
    [self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    self.mouseLocation = [self mouseLocationOnEvent:theEvent];
    self.clickPoint = CGPointZero;
    
    if ([self isMouseLocationInTextFrame]) {
        self.mouseState = SEMouseStateHover;
        
        SELinkText *link = [self linkAtPoint:self.mouseLocation];
        if (link) {
            [self clickedOnLink:link];
        }
    } else {
        self.mouseState = SEMouseStateNone;
    }
    
    [self setNeedsDisplay:YES];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    self.mouseLocation = [self mouseLocationOnEvent:theEvent];
    
    if ([self isMouseLocationInTextFrame]) {
        self.mouseState = SEMouseStateHover;
    } else {
        self.mouseState = SEMouseStateNone;
    }
    
    [self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    self.mouseLocation = [self mouseLocationOnEvent:theEvent];
    self.mouseState = SEMouseStateNone;
    
    [self setNeedsDisplay:YES];
}
#endif

- (BOOL)isMouseLocationInTextFrame
{
    return CGRectContainsPoint(self.textLayout.frameRect, self.mouseLocation);
}

- (CGPoint)shiftedMouseLocation
{
    return CGPointMake(self.mouseLocation.x - self.edgePadding.left, self.mouseLocation.y);
}

- (void)setHighlighted:(BOOL)highlighted
{
    _highlighted = highlighted;
    if (!self.attributedTextCopy) {
        self.attributedTextCopy = self.attributedText;
    }
    
    if (self.highlighted) {
        CGColorRef color = self.highlighted ? self.highlightedTextColor.CGColor : self.textColor.CGColor;
        [self setAttributes:@{(id)kCTForegroundColorAttributeName: (__bridge id)color}];
    } else {
        self.attributedText = self.attributedTextCopy;
        self.attributedTextCopy = nil;
    }
}

@end
