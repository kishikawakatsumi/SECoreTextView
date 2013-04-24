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

typedef NS_ENUM(NSUInteger, SETouchPhase) {
    SETouchPhaseNone       = 0,
    SETouchPhaseBegan      = 1 << 0,
    SETouchPhaseMoved      = 1 << 1,
    SETouchPhaseStationary = 1 << 2,
    SETouchPhaseEnded      = SETouchPhaseNone,
    SETouchPhaseCancelled  = SETouchPhaseNone,
    SETouchPhaseTouching   = SETouchPhaseBegan | SETouchPhaseMoved | SETouchPhaseStationary,
    SETouchPhaseAny        = NSUIntegerMax
};

@interface SETextView ()

@property (strong, nonatomic) SETextLayout *textLayout;

@property (assign, nonatomic) SETouchPhase touchPhase;
@property (assign, nonatomic) CGPoint clickPoint;
@property (assign, nonatomic) CGPoint mouseLocation;

@property (copy, nonatomic) NSAttributedString *attributedTextCopy;

#if TARGET_OS_IPHONE
@property (strong, nonatomic) SETextMagnifierCaret *magnifierCaret;
@property (strong, nonatomic) SESelectionGrabber *firstGrabber;
@property (strong, nonatomic) SESelectionGrabber *secondGrabber;
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
    self.firstGrabber = [[SESelectionGrabber alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
    [self addSubview:self.firstGrabber];
    
    self.secondGrabber = [[SESelectionGrabber alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
    [self addSubview:self.secondGrabber];
    
    [self hideSelectionGrabbers];
    
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
#if TARGET_OS_IPHONE
    self.selectionGestureRecognizer.enabled = self.selectable;
#endif
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
    
    NSDictionary *attributes = nil;
    
    CGColorRef color = NULL;
    if ([textColor respondsToSelector:@selector(CGColor)]) {
        color = textColor.CGColor;
        attributes = @{(id)kCTForegroundColorAttributeName: (__bridge id)color};
    } else {
        color = [textColor createCGColor];
        attributes = @{(id)kCTForegroundColorAttributeName: (__bridge id)color};
        CGColorRelease(color);
    }
    [self setAttributes:attributes];
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
    
    for (SELineLayout *lineLayout in self.textLayout.lineLayouts) {
        CGRect selectionRect = [lineLayout rectOfStringWithRange:textSelection.selectedRange];
        if (!CGRectIsEmpty(selectionRect)) {
            [self.selectedTextBackgroundColor set];
            CGFloat lineSpacing = self.lineSpacing;
            selectionRect.origin.y -= lineSpacing;
            selectionRect.size.height += lineSpacing;
            
            NSRectFill(selectionRect);
            
#if TARGET_OS_IPHONE
            if (!(self.touchPhase & SETouchPhaseTouching)) {
                [[UIColor colorWithRed:0.133 green:0.357 blue:0.718 alpha:1.000] set];
                NSRectFill(CGRectMake(selectionRect.origin.x,
                                      selectionRect.origin.y,
                                      2.0f,
                                      selectionRect.size.height));
                NSRectFill(CGRectMake(CGRectGetMaxX(selectionRect) - 2.0f,
                                      selectionRect.origin.y,
                                      2.0f,
                                      selectionRect.size.height));
            }
#endif
        }
    }
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
    
    [self enumerateLinksUsingBlock:^(SELinkText *link, BOOL *stop) {
        for (SETextGeometry *geometry in link.geometries) {
            [self addCursorRect:geometry.rect cursor:[NSCursor pointingHandCursor]];
        }
    }];
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

- (void)__highlightLinks
{
    [self enumerateLinksUsingBlock:^(SELinkText *link, BOOL *stop) {
        for (SETextGeometry *geometry in link.geometries) {
            [self.linkHighlightColor set];
            CGRect linkRect = geometry.rect;
            
            NSBezierPath *path = [self bezierPathWithRoundedRect:linkRect cornerRadius:3.0f];
            [path fill];
        }
    }];
}

- (void)highlightClickedLink
{
    if (self.touchPhase & SETouchPhaseTouching ||  self.touchPhase & SETouchPhaseStationary) {
        SELinkText *link = [self linkAtPoint:self.mouseLocation];
        for (SETextGeometry *geometry in link.geometries) {
            [self.linkHighlightColor set];
            CGRect linkRect = geometry.rect;
            
            NSBezierPath *path = [self bezierPathWithRoundedRect:linkRect cornerRadius:3.0f];
            [path fill];
        }
    }
}

- (void)highlightRolloveredLink
{
#if !TARGET_OS_IPHONE
    if (self.touchPhase == SETouchPhaseNone) {
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

- (NSBezierPath *)bezierPathWithRoundedRect:(CGRect)rect cornerRadius:(CGFloat)radius
{
#if TARGET_OS_IPHONE
    return [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius];
#else
    return [NSBezierPath bezierPathWithRoundedRect:rect xRadius:radius yRadius:radius];
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
    [self resetSelectionGrabber];
    
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
        self.magnifierCaret = [[SETextMagnifierCaret alloc] init];
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

- (void)resetSelectionGrabber
{
    if (self.touchPhase & SETouchPhaseTouching) {
        [self hideSelectionGrabbers];
        return;
    }
    
    SETextSelection *textSelection = self.textLayout.textSelection;
    if (!textSelection) {
        [self hideSelectionGrabbers];
        return;
    }
    
    NSInteger counter = 0;
    CGRect startRect = CGRectZero;
    CGRect endRect = CGRectZero;
    
    for (SELineLayout *lineLayout in self.textLayout.lineLayouts) {
        CGRect selectionRect = [lineLayout rectOfStringWithRange:textSelection.selectedRange];
        if (!CGRectIsEmpty(selectionRect)) {
            CGFloat lineSpacing = self.lineSpacing;
            selectionRect.origin.y -= lineSpacing;
            selectionRect.size.height += lineSpacing;
            
            if (counter == 0) {
                startRect = selectionRect;
                endRect = selectionRect;
            } else {
                endRect = selectionRect;
            }
            
            counter++;
        }
    }
    
    CGRect startFrame = startRect;
    startFrame.origin = CGPointMake(startFrame.origin.x - ceilf(CGRectGetHeight(endRect) / 2),
                                    startFrame.origin.y - CGRectGetHeight(startRect) + 8.0f);
    startFrame.size.width = CGRectGetHeight(startRect);
    startFrame.size.height = CGRectGetHeight(startRect);
    self.firstGrabber.frame = startFrame;
    
    CGRect endFrame = endRect;
    endFrame.origin = CGPointMake(CGRectGetMaxX(endRect) - ceilf(CGRectGetHeight(endRect) / 2),
                                  CGRectGetMaxY(endRect) - 8.0f);
    endFrame.size.width = CGRectGetHeight(endRect);
    endFrame.size.height = CGRectGetHeight(endRect);
    self.secondGrabber.frame = endFrame;
    
    [self showSelectionGrabbers];
}

- (void)showSelectionGrabbers
{
    self.firstGrabber.hidden = NO;
    self.secondGrabber.hidden = NO;
}

- (void)hideSelectionGrabbers
{
    self.firstGrabber.hidden = YES;
    self.secondGrabber.hidden = YES;
}

- (void)selectionChanged:(UILongPressGestureRecognizer *)gestureRecognizer
{
    self.mouseLocation = [gestureRecognizer locationInView:self];
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.touchPhase = SETouchPhaseBegan;
        CGPoint shiftedMouseLocation = [self shiftedMouseLocation];
        
        [self.textLayout setSelectionWithPoint:shiftedMouseLocation];
        
        [self showMagnifierCaretAtPoint:shiftedMouseLocation];
    } else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        self.touchPhase = SETouchPhaseMoved;
        CGPoint shiftedMouseLocation = [self shiftedMouseLocation];
        
        [self.textLayout setSelectionWithPoint:shiftedMouseLocation];
        
        [self moveMagnifierCaretToPoint:shiftedMouseLocation];
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded ||
               gestureRecognizer.state == UIGestureRecognizerStateCancelled ||
               gestureRecognizer.state == UIGestureRecognizerStateFailed) {
        self.touchPhase = SETouchPhaseNone;
        [self hideMagnifierCaret];
    }
    [self setNeedsDisplay];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.anyObject;
    self.mouseLocation = [touch locationInView:self];
    self.touchPhase = SETouchPhaseBegan;
    
    SETextSelection *textSelection = self.textLayout.textSelection;
    if (self.selectable && textSelection) {
        self.firstGrabber.dragging = CGRectContainsPoint(self.firstGrabber.frame, self.mouseLocation);
        self.secondGrabber.dragging = CGRectContainsPoint(self.secondGrabber.frame, self.mouseLocation);
    }
    
    [self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.anyObject;
    self.mouseLocation = [touch locationInView:self];
    self.touchPhase = SETouchPhaseNone;
    
    SETextSelection *textSelection = self.textLayout.textSelection;
    if (self.selectable && textSelection) {
        CGPoint shiftedMouseLocation = [self shiftedMouseLocation];
        if (self.firstGrabber.dragging) {
            CGPoint firstPoint = CGPointMake(shiftedMouseLocation.x, shiftedMouseLocation.y);
            [self.textLayout setSelectionStartWithFirstPoint:firstPoint];
        } else if (self.secondGrabber.dragging) {
            CGPoint endPoint = CGPointMake(shiftedMouseLocation.x, shiftedMouseLocation.y - CGRectGetHeight(self.secondGrabber.bounds));
            [self.textLayout setSelectionEndWithPoint:endPoint];
        }
    }
    
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.anyObject;
    self.mouseLocation = [touch locationInView:self];
        
    self.touchPhase = SETouchPhaseEnded;;
    self.clickPoint = CGPointZero;
    
    if ([self isMouseLocationInTextFrame]) {
        SELinkText *link = [self linkAtPoint:self.mouseLocation];
        if (link) {
            [self clickedOnLink:link];
        }
    }
    
    [self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.touchPhase = SETouchPhaseCancelled;
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
        self.touchPhase = SETouchPhaseBegan;
        [self.textLayout setSelectionStartWithPoint:[self shiftedMouseLocation]];
    }
    
    [self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    self.mouseLocation = [self mouseLocationOnEvent:theEvent];
    
    if ([self isMouseLocationInTextFrame]) {
        self.touchPhase = SETouchPhaseMoved;
        [self.textLayout setSelectionEndWithPoint:[self shiftedMouseLocation]];
    }
    
    [self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    self.mouseLocation = [self mouseLocationOnEvent:theEvent];
    self.clickPoint = CGPointZero;
    
    self.touchPhase = SETouchPhaseEnded;
    
    if ([self isMouseLocationInTextFrame]) {
        SELinkText *link = [self linkAtPoint:self.mouseLocation];
        if (link) {
            [self clickedOnLink:link];
        }
    }
    
    [self setNeedsDisplay:YES];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    self.mouseLocation = [self mouseLocationOnEvent:theEvent];
    [self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    self.mouseLocation = [self mouseLocationOnEvent:theEvent];
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
