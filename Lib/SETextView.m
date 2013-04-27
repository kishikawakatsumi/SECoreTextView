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
#import "SETextAttachment.h"
#import "SETextSelection.h"
#import "SETextMagnifierCaret.h"
#import "SETextMagnifierRanged.h"
#import "SESelectionGrabber.h"
#import "SELinkText.h"
#import "SETextGeometry.h"
#import "SEConstants.h"

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

NSString * const OBJECT_REPLACEMENT_CHARACTER = @"\uFFFC";

@interface SETextView ()

@property (strong, nonatomic) SETextLayout *textLayout;

@property (strong, nonatomic) NSMutableArray *attachments;

@property (assign, nonatomic) SETouchPhase touchPhase;
@property (assign, nonatomic) CGPoint clickPoint;
@property (assign, nonatomic) CGPoint mouseLocation;

@property (copy, nonatomic) NSAttributedString *attributedTextCopy;

#if TARGET_OS_IPHONE
@property (strong, nonatomic) UILongPressGestureRecognizer *selectionGestureRecognizer;
@property (strong, nonatomic) SETextMagnifierCaret *magnifierCaret;
@property (strong, nonatomic) SETextMagnifierRanged *magnifierRanged;
@property (strong, nonatomic) UIPanGestureRecognizer *firstGrabberGestureRecognizer;
@property (strong, nonatomic) UIPanGestureRecognizer *secondGrabberGestureRecognizer;
@property (strong, nonatomic) SESelectionGrabber *firstGrabber;
@property (strong, nonatomic) SESelectionGrabber *secondGrabber;
#endif

@end

@implementation SETextView

- (void)commonInit
{
    self.textLayout = [[SETextLayout alloc] init];
    self.textLayout.bounds = self.bounds;
    
    self.attachments = [[NSMutableArray alloc] init];
    
    self.highlightedTextColor = [NSColor whiteColor];
    self.selectedTextBackgroundColor = [SEConstants selectedTextBackgroundColor];
    self.linkHighlightColor = [SEConstants selectedTextBackgroundColor];
    self.linkRolloverEffectColor = [SEConstants linkColor];
    
#if TARGET_OS_IPHONE
    self.showsEditingMenuAutomatically = YES;
    
    self.magnifierCaret = [[SETextMagnifierCaret alloc] init];
    self.magnifierRanged = [[SETextMagnifierRanged alloc] init];
    
    [self setupSelectionGestureRecognizers];
    
    [self becomeFirstResponder];
#endif
}

#if TARGET_OS_IPHONE
- (void)setupSelectionGestureRecognizers
{
    self.selectionGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(selectionChanged:)];
    self.selectionGestureRecognizer.enabled = NO;
    [self addGestureRecognizer:self.selectionGestureRecognizer];
    
    self.firstGrabber = [[SESelectionGrabber alloc] init];
    self.firstGrabber.dotMetric = SESelectionGrabberDotMetricTop;
    [self addSubview:self.firstGrabber];
    
    self.secondGrabber = [[SESelectionGrabber alloc] init];
    self.secondGrabber.dotMetric = SESelectionGrabberDotMetricBottom;
    [self addSubview:self.secondGrabber];
    
    self.firstGrabberGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(grabberMoved:)];
    [self.firstGrabber addGestureRecognizer:self.firstGrabberGestureRecognizer];
    
    self.secondGrabberGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(grabberMoved:)];
    [self.secondGrabber addGestureRecognizer:self.secondGrabberGestureRecognizer];
}
#endif

- (void)awakeFromNib
{
    [self commonInit];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
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
                                    lineSpacing:0.0f];
}

+ (CGRect)frameRectWithAttributtedString:(NSAttributedString *)attributedString
                          constraintSize:(CGSize)constraintSize
                             lineSpacing:(CGFloat)lineSpacing
{
    return [self frameRectWithAttributtedString:attributedString
                                 constraintSize:constraintSize
                                    lineSpacing:lineSpacing
                                           font:nil];
}

+ (CGRect)frameRectWithAttributtedString:(NSAttributedString *)attributedString
                          constraintSize:(CGSize)constraintSize
                             lineSpacing:(CGFloat)lineSpacing
                                    font:(NSFont *)font
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

- (CGSize)sizeThatFits:(CGSize)size
{
    [self setAdditionalAttributes];
    
    CGRect frameRect = [self.class frameRectWithAttributtedString:self.attributedText
                                                   constraintSize:size
                                                      lineSpacing:self.lineSpacing
                                                             font:self.font];
    return frameRect.size;
}

- (void)sizeToFit
{
    CGSize size = [self sizeThatFits:self.bounds.size];
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

#pragma mark -

- (void)setSelectable:(BOOL)selectable
{
    _selectable = selectable;
#if TARGET_OS_IPHONE
    self.selectionGestureRecognizer.enabled = self.selectable;
    self.firstGrabberGestureRecognizer.enabled = self.selectable;
    self.secondGrabberGestureRecognizer.enabled = self.selectable;
#endif
}

- (void)setText:(NSString *)text
{
    _text = text;
    if (self.text) {
        self.attributedText = [[NSAttributedString alloc] initWithString:text];
    } else {
        self.attributedText = nil;
    }
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    _attributedText = [attributedText copy];
    _text = _attributedText.string;
    
    [self setNeedsDisplayInRect:self.bounds];
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

- (CGRect)layoutFrame
{
    return self.textLayout.frameRect;
}

- (NSRange)selectedRange
{
    return self.textLayout.textSelection.selectedRange;
}

- (NSString *)selectedText
{
    return [self.text substringWithRange:self.selectedRange];
}

- (NSAttributedString *)selectedAttributedText
{
    return [self.attributedText attributedSubstringFromRange:self.selectedRange];
}

#pragma mark -

- (void)addObject:(id)object size:(CGSize)size atIndex:(NSInteger)index
{
    [self addObject:object size:size replaceRange:NSMakeRange(index, 0)];
}

- (void)addObject:(id)object size:(CGSize)size replaceRange:(NSRange)range
{
    NSRange raplaceRange = NSMakeRange(range.location, OBJECT_REPLACEMENT_CHARACTER.length);
    SETextAttachment *attachment = [[SETextAttachment alloc] initWithObject:object size:size range:raplaceRange];
    [self.attachments addObject:attachment];
}

- (void)setAdditionalAttributes
{
    [self setFontAttributes];
    [self setTextColorAttributes];
    [self setTextAttachmentAttributes];
}

- (void)setFontAttributes
{
    if (!self.font) {
        return;
    }
    
    CFStringRef fontName = (__bridge CFStringRef)self.font.fontName;
    CGFloat fontSize = self.font.pointSize;
	CTFontRef ctfont = CTFontCreateWithName(fontName, fontSize, NULL);
    [self setAttributes:@{(id)kCTFontAttributeName: (__bridge id)ctfont}];
	CFRelease(ctfont);
}

- (void)setTextColorAttributes
{
    if (!self.textColor) {
        return;
    }
    
#if TARGET_OS_IPHONE
    CGColorRef color = self.textColor.CGColor;
    [self setAttributes:@{(id)kCTForegroundColorAttributeName: (__bridge id)color}];
#else
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
#endif
}

- (void)setTextAttachmentAttributes
{
    for (SETextAttachment *attachment in self.attachments) {
        NSRange range = attachment.range;
        
        NSMutableAttributedString *attributedString = [self.attributedText mutableCopy];
        if (range.length > 0) {
            [attributedString replaceCharactersInRange:range withString:OBJECT_REPLACEMENT_CHARACTER];
        } else {
            NSAttributedString *replacement = [[NSAttributedString alloc] initWithString:OBJECT_REPLACEMENT_CHARACTER];
            [attributedString insertAttributedString:replacement atIndex:range.location];
        }
        
#if TARGET_OS_IPHONE
        CTRunDelegateCallbacks callbacks = attachment.callbacks;
        CTRunDelegateRef delegateRef = CTRunDelegateCreate(&callbacks, (__bridge void *)attachment);
        
        [attributedString addAttributes:@{(id)kCTRunDelegateAttributeName: (__bridge id)delegateRef} range:attachment.range];
        
        self.attributedText = attributedString;
#endif
    }
}

- (void)setAttributes:(NSDictionary *)attributes
{
    NSInteger length = self.attributedText.length;
    NSMutableAttributedString *attributedString = [self.attributedText mutableCopy];
    
    if (attributes) {
        [attributedString addAttributes:attributes range:NSMakeRange(0, length)];
    }
    
    self.attributedText = attributedString;
}

#pragma mark -

- (void)clearSelection
{
    self.textLayout.textSelection = nil;
}

- (void)finishSelecting
{
#if TARGET_OS_IPHONE
    if (self.showsEditingMenuAutomatically) {
        [self hideEditingMenu];
        [self showEditingMenu];
    }
#endif
    
    if ([self respondsToSelector:@selector(textViewDidEndSelecting:)]) {
        [self.delegate textViewDidEndSelecting:self];
    }
}

- (void)notifySelectionChanged
{
    if ([self.delegate respondsToSelector:@selector(textViewDidChangeSelection:)]) {
        [self.delegate textViewDidChangeSelection:self];
    }
}

- (void)clickedOnLink:(SELinkText *)link
{
    if ([self.delegate respondsToSelector:@selector(textView:clickedOnLink:atIndex:)]) {
        [self.delegate textView:self clickedOnLink:link atIndex:[self stringIndexAtPoint:self.mouseLocation]];
    }
}

#pragma mark -

- (void)drawTextAttachmentsInContext:(CGContextRef)context
{
#if TARGET_OS_IPHONE
    for (SETextAttachment *attachment in self.attachments) {
        for (SELineLayout *lineLayout in self.textLayout.lineLayouts) {
            CGRect rect = [lineLayout rectOfStringWithRange:attachment.range];
            if (!CGRectIsEmpty(rect)) {
                if ([attachment.object isKindOfClass:[UIView class]]) {
                    UIView *view = attachment.object;
                    view.frame = rect;
                    if (!view.superview) {
                        [self addSubview:view];
                    }
                } else if ([attachment.object isKindOfClass:[UIImage class]]) {
                    UIImage *image = attachment.object;
                    [image drawInRect:rect];
                } else if ([attachment.object isKindOfClass:NSClassFromString(@"NSBlock")]) {
                    SETextAttachmentDrawBlock draw = attachment.object;
                    CGContextSaveGState(context);
                    draw(rect, context);
                    CGContextRestoreGState(context);
                }
            }
        }
    }
#endif
}

- (void)highlightSelection
{
    SETextSelection *textSelection = self.textLayout.textSelection;
    if (!textSelection) {
        return;
    }
    
#if TARGET_OS_IPHONE
    CGRect topRect = CGRectNull;
    CGRect bottomRect = CGRectNull;
#endif
    
    for (SELineLayout *lineLayout in self.textLayout.lineLayouts) {
        CGRect selectionRect = [lineLayout rectOfStringWithRange:textSelection.selectedRange];
        if (!CGRectIsEmpty(selectionRect)) {
            [self.selectedTextBackgroundColor set];
            
            CGFloat lineSpacing = self.lineSpacing;
            selectionRect.origin.y -= lineSpacing;
            selectionRect.size.height += lineSpacing;
            
            NSRectFill(selectionRect);
            
#if TARGET_OS_IPHONE
            if (CGRectIsNull(topRect)) {
                topRect = selectionRect;
            }
            bottomRect = selectionRect;
#endif
        }
    }
    
#if TARGET_OS_IPHONE
    if (!(self.touchPhase & SETouchPhaseTouching)) {
        [[SEConstants selectionGrabberColor] set];
        NSRectFill(CGRectMake(CGRectGetMinX(topRect) - 2.0f,
                              topRect.origin.y,
                              2.0f,
                              topRect.size.height));
        NSRectFill(CGRectMake(CGRectGetMaxX(bottomRect),
                              bottomRect.origin.y,
                              2.0f,
                              bottomRect.size.height));
    }
#endif
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

- (BOOL)containsPointInSelection:(CGPoint)point
{
    CFIndex index = [self stringIndexAtPoint:point];
    NSRange selectedRange = self.selectedRange;
    return NSLocationInRange(index, selectedRange);
}

- (BOOL)containsPointInTextFrame:(CGPoint)point
{
    return CGRectContainsPoint(self.textLayout.frameRect, point);
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
    if (self.touchPhase & SETouchPhaseBegan || self.touchPhase & SETouchPhaseStationary) {
        SELinkText *link = [self linkAtPoint:self.mouseLocation];
        for (SETextGeometry *geometry in link.geometries) {
            [self.linkHighlightColor set];
            CGRect linkRect = geometry.rect;
            
            NSBezierPath *path = [self bezierPathWithRoundedRect:linkRect cornerRadius:3.0f];
            [path fill];
        }
    }
}

#if !TARGET_OS_IPHONE
- (void)highlightRolloveredLink
{
    if (self.touchPhase == SETouchPhaseNone) {
        SELinkText *link = [self linkAtPoint:self.mouseLocation];
        for (SETextGeometry *geometry in link.geometries) {
            [self.linkRolloverEffectColor set];
            CGRect linkRect = geometry.rect;
            linkRect.size.height = 1.0f;
            
            NSRectFill(linkRect);
        }
    }
}

- (void)updateCursorRectsInLinks
{
    [self discardCursorRects];
    
    [self addCursorRect:self.textLayout.frameRect cursor:[NSCursor IBeamCursor]];
    
    [self enumerateLinksUsingBlock:^(SELinkText *link, BOOL *stop) {
        for (SETextGeometry *geometry in link.geometries) {
            [self addCursorRect:geometry.rect cursor:[NSCursor pointingHandCursor]];
        }
    }];
}

- (void)updateTrackingAreasInLinks
{
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
}
#endif

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
    
#if TARGET_OS_IPHONE
    CGContextRef context = UIGraphicsGetCurrentContext();
#else
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
#endif
	
    [self setAdditionalAttributes];
    
    self.textLayout.bounds = self.bounds;
    self.textLayout.attributedString = self.attributedText;
    
    [self.textLayout update];
    
    [self highlightSelection];
    
    [self highlightClickedLink];
    
    [self drawTextAttachmentsInContext:context];
    
#if TARGET_OS_IPHONE
    [self resetSelectionGrabber];
#else
    [self highlightRolloveredLink];
    
    [self updateCursorRectsInLinks];
    [self updateTrackingAreasInLinks];
#endif
    
#if TARGET_OS_IPHONE
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
#endif
    
    [self.textLayout drawInContext:context];
}

#pragma mark - iOS touch events
#if TARGET_OS_IPHONE

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (self.selectable) {
        return [super hitTest:point withEvent:event];
    }
    
    SELinkText *link = [self linkAtPoint:point];
    if (link) {
        return [super hitTest:point withEvent:event];
    }
    
    return nil;
}

- (void)moveMagnifierCaretToPoint:(CGPoint)point
{
    if (!self.magnifierCaret.superview) {
        [self.magnifierCaret showInView:self.window atPoint:[self convertPoint:point toView:nil]];
    }
    [self.magnifierCaret moveToPoint:[self convertPoint:point toView:nil]];
}

- (void)hideMagnifierCaret
{
    [self.magnifierCaret hide];
}

- (void)moveMagnifierRangedToPoint:(CGPoint)point
{
    if (!self.magnifierRanged.superview) {
        [self.magnifierRanged showInView:self.window atPoint:[self convertPoint:point toView:nil]];
    }
    [self.magnifierRanged moveToPoint:[self convertPoint:point toView:nil]];
}

- (void)hideMagnifierRanged
{
    [self.magnifierRanged hide];
}

- (void)resetSelectionGrabber
{
    if (!self.selectable) {
        self.firstGrabberGestureRecognizer.enabled = NO;
        self.secondGrabberGestureRecognizer.enabled = NO;
        [self hideSelectionGrabbers];
        return;
    }
    
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
                                    startFrame.origin.y);
    startFrame.size.width = CGRectGetHeight(startRect);
    startFrame.size.height = CGRectGetHeight(startRect) + self.lineSpacing;
    self.firstGrabber.frame = startFrame;
    
    CGRect endFrame = endRect;
    endFrame.origin = CGPointMake(CGRectGetMaxX(endRect) - ceilf(CGRectGetHeight(endRect) / 2),
                                  CGRectGetMinY(endRect));
    endFrame.size.width = CGRectGetHeight(endRect);
    endFrame.size.height = CGRectGetHeight(endRect) + self.lineSpacing;
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
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan ||
        gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        self.touchPhase = SETouchPhaseMoved;
        CGPoint shiftedMouseLocation = self.mouseLocation;
        
        [self.textLayout setSelectionWithPoint:shiftedMouseLocation];
        
        [self moveMagnifierCaretToPoint:self.mouseLocation];
    } if (gestureRecognizer.state == UIGestureRecognizerStateEnded ||
               gestureRecognizer.state == UIGestureRecognizerStateCancelled ||
               gestureRecognizer.state == UIGestureRecognizerStateFailed) {
        self.touchPhase = SETouchPhaseNone;
        [self hideMagnifierCaret];
        
        [self finishSelecting];
    }
    
    [self notifySelectionChanged];
    
    [self setNeedsDisplay];
}

- (void)grabberMoved:(UIPanGestureRecognizer *)gestureRecognizer
{
    SETextSelection *textSelection = self.textLayout.textSelection;
    if (!self.selectable || !textSelection) {
        return;
    }
    
    self.touchPhase = SETouchPhaseNone;
    
    self.mouseLocation = [gestureRecognizer locationInView:self];
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan ||
        gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        if (gestureRecognizer == self.firstGrabberGestureRecognizer) {
            self.firstGrabber.dragging = YES;
            
            [self.textLayout setSelectionStartWithFirstPoint:self.mouseLocation];
            [self moveMagnifierRangedToPoint:self.firstGrabber.center];
        } else {
            [self.textLayout setSelectionEndWithPoint:self.mouseLocation];
            [self moveMagnifierRangedToPoint:self.secondGrabber.center];
        }
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded ||
               gestureRecognizer.state == UIGestureRecognizerStateCancelled ||
               gestureRecognizer.state == UIGestureRecognizerStateFailed) {
        if (gestureRecognizer == self.firstGrabberGestureRecognizer) {
            self.firstGrabber.dragging = NO;
        } else {
            self.secondGrabber.dragging = NO;
        }
        
        [self hideMagnifierRanged];
        
        if (self.textLayout.textSelection) {
            [self finishSelecting];
        }
    }
    
    [self notifySelectionChanged];
    
    [self setNeedsDisplay];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{    
    UITouch *touch = touches.anyObject;
    self.mouseLocation = [touch locationInView:self];
    self.touchPhase = SETouchPhaseBegan;
    
    [self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.selectionGestureRecognizer.state == UIGestureRecognizerStateBegan ||
        self.selectionGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        self.touchPhase = SETouchPhaseMoved;
    } else {
        self.touchPhase = SETouchPhaseCancelled;
    }
    
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.anyObject;
    self.mouseLocation = [touch locationInView:self];
        
    self.touchPhase = SETouchPhaseEnded;;
    self.clickPoint = CGPointZero;
    
    if (![self containsPointInSelection:self.mouseLocation]) {
        [self.textLayout clearSelection];
        [self hideEditingMenu];
    }
    
    if ([self containsPointInTextFrame:self.mouseLocation]) {
        SELinkText *link = [self linkAtPoint:self.mouseLocation];
        if (link) {
            [self clickedOnLink:link];
            
            [self.textLayout clearSelection];
            [self hideEditingMenu];
        }
    }
    
    [self setNeedsDisplay];
}

#pragma mark -

- (void)showEditingMenu
{
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    menuController.arrowDirection = UIMenuControllerArrowDefault;
    [menuController setTargetRect:[self editingMenuRectForSelection] inView:self];
    
    [menuController setMenuVisible:YES animated:YES];
}

- (void)hideEditingMenu
{
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    [menuController setMenuVisible:NO animated:YES];
}

- (CGRect)editingMenuRectForSelection
{
    SETextSelection *textSelection = self.textLayout.textSelection;
    CGRect topRect = CGRectNull;
    CGFloat minX = CGFLOAT_MAX;
    CGFloat maxX = CGFLOAT_MIN;
    
    for (SELineLayout *lineLayout in self.textLayout.lineLayouts) {
        CGRect selectionRect = [lineLayout rectOfStringWithRange:textSelection.selectedRange];
        if (!CGRectIsEmpty(selectionRect)) {
            CGFloat lineSpacing = self.lineSpacing;
            selectionRect.origin.y -= lineSpacing;
            selectionRect.size.height += lineSpacing;
            
            if (CGRectIsNull(topRect)) {
                topRect = selectionRect;
            }
            
            minX = MIN(CGRectGetMinX(selectionRect), minX);
            maxX = MAX(CGRectGetMaxX(selectionRect), maxX);
            
            topRect.origin.x = minX;
            topRect.size.width = maxX - minX;
        }
    }
    
    return topRect;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return action == @selector(copy:) || (action == @selector(selectAll:) && self.selectedText.length < self.text.length);
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma mark - OS X mouse events
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
        [self.textLayout setSelectionStartWithPoint:self.mouseLocation];
    }
    
    [self notifySelectionChanged];
    
    [self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    self.mouseLocation = [self mouseLocationOnEvent:theEvent];
    
    if ([self isMouseLocationInTextFrame]) {
        self.touchPhase = SETouchPhaseMoved;
        [self.textLayout setSelectionEndWithPoint:self.mouseLocation];
    }
    
    [self notifySelectionChanged];
    
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

- (BOOL)acceptsFirstResponder
{
    return YES;
}

#endif
#pragma mark - Common

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

- (void)copy:(id)sender
{
#if TARGET_OS_IPHONE
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = self.selectedText;
#else
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard writeObjects:[NSArray arrayWithObject:self.selectedAttributedText]];
#endif
}

- (void)selectAll:(id)sender
{
    [self.textLayout selectAll];
    
#if TARGET_OS_IPHONE
    [self finishSelecting];
#endif
    
    [self setNeedsDisplayInRect:self.bounds];
}

- (BOOL)resignFirstResponder
{
    [self.textLayout clearSelection];
    [self setNeedsDisplayInRect:self.bounds];
    
    return YES;
}

@end
