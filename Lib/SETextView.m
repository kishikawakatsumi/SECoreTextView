//
//  SETextView.m
//  SECoreTextView
//
//  Created by kishikawa katsumi on 2013/04/20.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import "SETextView.h"
#import "SETextInput.h"
#import "SETextLayout.h"
#import "SELineLayout.h"
#import "SETextAttachment.h"
#import "SETextSelection.h"
#import "SETextSelectionView.h"
#import "SETextEditingCaret.h"
#import "SETextMagnifierCaret.h"
#import "SETextMagnifierRanged.h"
#import "SESelectionGrabber.h"
#import "SELinkText.h"
#import "SETextGeometry.h"
#import "SEConstants.h"

typedef NS_ENUM (NSUInteger, SETouchPhase) {
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

@property (nonatomic) SETextLayout *textLayout;

@property (nonatomic) NSMutableArray *attachments;

@property (nonatomic) SETouchPhase touchPhase;
@property (nonatomic) CGPoint clickPoint;
@property (nonatomic) CGPoint mouseLocation;

@property (nonatomic, copy) NSAttributedString *attributedTextCopy;

@property (nonatomic, weak) NSTimer *longPressTimer;
@property (nonatomic, getter = isLongPressing) BOOL longPressing;

#if TARGET_OS_IPHONE
@property (nonatomic) UITextInputStringTokenizer *tokenizer;

@property (nonatomic) SETextMagnifierCaret *magnifierCaret;
@property (nonatomic) SETextMagnifierRanged *magnifierRanged;

@property (nonatomic) SETextSelectionView *textSelectionView;
@property (nonatomic) SETextEditingCaret *caretView;
#endif

@end

@implementation SETextView

#if TARGET_OS_IPHONE
@synthesize inputDelegate;
@synthesize markedTextStyle;
#endif

- (void)commonInit
{
    self.textLayout = [[SETextLayout alloc] init];
    self.textLayout.bounds = self.bounds;
    
    self.attachments = [[NSMutableArray alloc] init];
    
    self.highlightedTextColor = [NSColor whiteColor];
    self.selectedTextBackgroundColor = [SEConstants selectedTextBackgroundColor];
    self.linkHighlightColor = [SEConstants selectedTextBackgroundColor];
    self.linkRolloverEffectColor = [SEConstants linkColor];
    
    self.minimumLongPressDuration = 0.5;
    
#if TARGET_OS_IPHONE
    self.showsEditingMenuAutomatically = YES;
    
    self.magnifierCaret = [[SETextMagnifierCaret alloc] init];
    self.magnifierRanged = [[SETextMagnifierRanged alloc] init];
    
    [self setupTextSelectionControls];
    [self setupTextEditingControls];
    
    self.backgroundColor = [UIColor clearColor];
#endif
}

#if TARGET_OS_IPHONE
- (void)setupTextSelectionControls
{
    CGRect frame = self.bounds;
    self.textSelectionView = [[SETextSelectionView alloc] initWithFrame:frame textView:self];
    self.textSelectionView.userInteractionEnabled = NO;
    self.textSelectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.textSelectionView];
}

- (void)setupTextEditingControls
{
    self.caretView = [[SETextEditingCaret alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 2.0f, 0.0f)];
    [self addSubview:self.caretView];
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
    NSInteger length = attributedString.length;
    NSMutableAttributedString *mutableAttributedString = [attributedString mutableCopy];
    
    CTTextAlignment textAlignment = kCTTextAlignmentNatural;
    CGFloat lineHeight = 0.0f;
    CGFloat paragraphSpacing = 0.0f;
    
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
    [mutableAttributedString addAttributes:@{(id)kCTParagraphStyleAttributeName: (__bridge id)paragraphStyle} range:NSMakeRange(0, length)];
    CFRelease(paragraphStyle);
    
    attributedString = mutableAttributedString;
    
    if (font) {
        CFStringRef fontName = (__bridge CFStringRef)font.fontName;
        CGFloat fontSize = font.pointSize;
        CTFontRef ctfont = CTFontCreateWithName(fontName, fontSize, NULL);
        [mutableAttributedString addAttributes:@{(id)kCTFontAttributeName: (__bridge id)ctfont} range:NSMakeRange(0, length)];
        CFRelease(ctfont);
        
        attributedString = mutableAttributedString;
    }
    
    return [SETextLayout frameRectWithAttributtedString:attributedString
                                         constraintSize:constraintSize];
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
    CGSize size = [self sizeThatFits:CGSizeMake(CGRectGetWidth(self.bounds), CGFLOAT_MAX)];
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

#pragma mark -

- (void)setSelectable:(BOOL)selectable
{
    _selectable = selectable;
#if TARGET_OS_IPHONE
    self.textSelectionView.userInteractionEnabled = self.isSelectable;
#endif
}

- (void)setEditable:(BOOL)editable
{
    _editable = editable;
    if (self.isEditable) {
        self.selectable = YES;
    }
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

- (NSMutableString *)editingText
{
    return self.text ? self.text.mutableCopy : [[NSMutableString alloc] init];
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
    [self setParagraphStyle];
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
    if ([self.textColor respondsToSelector:@selector(CGColor)]) {
        color = self.textColor.CGColor;
        attributes = @{(id)kCTForegroundColorAttributeName: (__bridge id)color};
    } else {
        color = [self.textColor createCGColor];
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
        
        CTRunDelegateCallbacks callbacks = attachment.callbacks;
        CTRunDelegateRef delegateRef = CTRunDelegateCreate(&callbacks, (__bridge void *)attachment);
        [attributedString addAttributes:@{(id)kCTRunDelegateAttributeName: (__bridge id)delegateRef} range:attachment.range];
        CFRelease(delegateRef);
        
        self.attributedText = attributedString;
    }
}

- (void)setParagraphStyle
{
#if TARGET_OS_IPHONE
    CTTextAlignment textAlignment;
    if (self.textAlignment == NSTextAlignmentRight) {
        textAlignment = kCTTextAlignmentCenter;
    } else if (self.textAlignment == NSTextAlignmentCenter) {
        textAlignment = kCTTextAlignmentRight;
    } else {
        textAlignment = (CTTextAlignment)self.textAlignment;
    }
//    CTTextAlignment textAlignment = NSTextAlignmentToCTTextAlignment(self.textAlignment);
#else
    CTTextAlignment textAlignment = self.textAlignment;
#endif
    CGFloat lineSpacing = roundf(self.lineSpacing);
    CGFloat lineHeight = roundf(self.lineHeight);
    CGFloat paragraphSpacing = roundf(self.paragraphSpacing);
    
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
    [self setAttributes:@{(id)kCTParagraphStyleAttributeName: (__bridge id)paragraphStyle}];
    CFRelease(paragraphStyle);
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

- (void)updateLayout
{
    [self setAdditionalAttributes];
    
    self.textLayout.bounds = self.bounds;
    self.textLayout.attributedString = self.attributedText;
    
    [self.textLayout update];
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

- (void)selectionChanged
{
    SETextLayout *textLayout = self.textLayout;
    SETextSelection *textSelection = textLayout.textSelection;
    if (self.isEditing && (!textSelection || textSelection.selectedRange.length == 0)) {
        self.caretView.hidden = NO;
        [self.caretView delayBlink];
    } else {
        self.caretView.hidden = YES;
    }
    
    [self notifySelectionChanged];
    [self setNeedsDisplayInRect:self.bounds];
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

- (void)longPressedOnLink:(SELinkText *)link
{
    if ([self.delegate respondsToSelector:@selector(textView:longPressedOnLink:atIndex:)]) {
        [self.delegate textView:self longPressedOnLink:link atIndex:[self stringIndexAtPoint:self.mouseLocation]];
    }
}

#pragma mark -

- (CFIndex)stringIndexAtPoint:(CGPoint)point
{
    return [self.textLayout stringIndexForPosition:point];
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

- (void)drawTextAttachmentsInContext:(CGContextRef)context
{
    for (SETextAttachment *attachment in self.attachments) {
        for (SELineLayout *lineLayout in self.textLayout.lineLayouts) {
            CGRect rect = [lineLayout rectOfStringWithRange:attachment.range];
            if (!CGRectIsEmpty(rect)) {
                if ([attachment.object isKindOfClass:[NSView class]]) {
                    UIView *view = attachment.object;
                    view.frame = rect;
                    if (!view.superview) {
                        [self addSubview:view];
                    }
                } else if ([attachment.object isKindOfClass:[NSImage class]]) {
                    NSImage *image = attachment.object;
#if TARGET_OS_IPHONE
                    [image drawInRect:rect];
#else
                    [image drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
#endif
                } else if ([attachment.object isKindOfClass:NSClassFromString(@"NSBlock")]) {
                    SETextAttachmentDrawingBlock draw = attachment.object;
                    CGContextSaveGState(context);
                    draw(rect, context);
                    CGContextRestoreGState(context);
                }
            }
        }
    }
}

- (void)highlightSelection
{
    SETextSelection *textSelection = self.textLayout.textSelection;
    NSRange selectedRange = textSelection.selectedRange;
    if (!textSelection || selectedRange.location == NSNotFound) {
        return;
    }
    
    NSInteger lineNumber = 0;
    CGRect startRect = CGRectZero;
    CGRect endRect = CGRectZero;
    
    CGFloat lineSpacing = self.lineSpacing;
    CGFloat previousLineOffset = 0.0f;
    
    for (SELineLayout *lineLayout in self.textLayout.lineLayouts) {
        NSRange stringRange = lineLayout.stringRange;
        
        NSRange intersectionRange = NSIntersectionRange(selectedRange, stringRange);
        if (intersectionRange.location == NSNotFound) {
            continue;
        }
        
        CGRect selectionRect = [lineLayout rectOfStringWithRange:selectedRange];
        if (CGRectIsEmpty(selectionRect)) {
            continue;
        }
        
        [self.selectedTextBackgroundColor set];
        
        selectionRect.origin.y -= lineSpacing;
        selectionRect.size.height += lineSpacing;
        if (selectionRect.origin.y < 0.0f) {
            selectionRect.size.height += selectionRect.origin.y;
            selectionRect.origin.y = 0.0f;
        }
        
        if (NSMaxRange(selectedRange) != NSMaxRange(stringRange) && NSMaxRange(intersectionRange) == NSMaxRange(stringRange)) {
            selectionRect.size.width = CGRectGetWidth(self.bounds) - CGRectGetMinX(selectionRect);
        }
        
        if (previousLineOffset > 0.0f) {
            CGFloat delta = CGRectGetMinY(selectionRect) - previousLineOffset;
            selectionRect.origin.y -= delta;
            selectionRect.size.height += delta;
        }
        
        selectionRect = CGRectIntegral(selectionRect);
        
        UIRectFill(selectionRect);
        
        if (lineNumber == 0) {
            startRect = selectionRect;
            endRect = selectionRect;
        } else {
            endRect = selectionRect;
        }
        
        previousLineOffset = CGRectGetMaxY(selectionRect);
        
        lineNumber++;
    }
    
    self.textSelectionView.startFrame = startRect;
    self.textSelectionView.endFrame = endRect;
}

- (void)highlightMarkedText
{
    NSRange markedTextRange = self.textLayout.markedTextRange;
    if (markedTextRange.location != NSNotFound && markedTextRange.length > 0) {
        for (SELineLayout *lineLayout in self.textLayout.lineLayouts) {
            CGRect markedRect = [lineLayout rectOfStringWithRange:markedTextRange];
            if (!CGRectIsEmpty(markedRect)) {
                [self.selectedTextBackgroundColor set];
                
                CGFloat lineSpacing = self.lineSpacing;
                markedRect.origin.y -= lineSpacing;
                markedRect.size.height += lineSpacing;
                
                NSRectFill(markedRect);
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
    [self updateLayout];
    
    [self highlightSelection];
    
    if (self.isEditing) {
        [self highlightMarkedText];
    }
    
    [self highlightClickedLink];
    
    [self drawTextAttachmentsInContext:context];
    
#if TARGET_OS_IPHONE
    [self resetSelectionGrabber];
#else
    [self highlightRolloveredLink];
    
    [self updateCursorRectsInLinks];
    [self updateTrackingAreasInLinks];
#endif
    
    [self.textLayout drawInContext:context];
}

#pragma mark - Touch and Hold on Link

- (void)startLongPressTimer
{
    [self stopLongPressTimer];
    
    NSTimer *holdTimer = [NSTimer scheduledTimerWithTimeInterval:self.minimumLongPressDuration
                                                          target:self
                                                        selector:@selector(handleLongPress:)
                                                        userInfo:nil
                                                         repeats:NO];
    self.longPressTimer = holdTimer;
}

- (void)stopLongPressTimer
{
    if (self.longPressTimer && [self.longPressTimer isValid]) {
        [self.longPressTimer invalidate];
    }
    
    self.longPressTimer = nil;
}

- (void)handleLongPress:(NSTimer *)timer
{
    [self stopLongPressTimer];
    
    if ([self containsPointInTextFrame:self.mouseLocation]) {
        SELinkText *link = [self linkAtPoint:self.mouseLocation];
        if (link) {
            [self longPressedOnLink:link];
            
#if TARGET_OS_IPHONE
            [self clearSelection];
            [self hideEditingMenu];
#endif
            
            self.longPressing = YES;
        }
    }
}

#pragma mark - iOS touch events
#if TARGET_OS_IPHONE

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (self.isHidden || self.userInteractionEnabled == NO || self.alpha < 0.01f) {
        return [super hitTest:point withEvent:event];
    }
    
    if (self.selectable || self.editable) {
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
        [self hideTextSelectionView];
        return;
    }
    
    if (self.touchPhase & SETouchPhaseTouching) {
        [self hideTextSelectionView];
        return;
    }
    
    SETextLayout *textLayout = self.textLayout;
    SETextSelection *textSelection = textLayout.textSelection;
    if (!textSelection || textSelection.selectedRange.length == 0) {
        [self hideTextSelectionView];
        return;
    }
    
    [self.textSelectionView update];
    
    [self showTextSelectionView];
}

- (void)showTextSelectionView
{
    [self.textSelectionView showControls];
}

- (void)hideTextSelectionView
{
    [self.textSelectionView hideControls];
    [self hideEditingMenu];
}

- (void)selectionChanged:(UILongPressGestureRecognizer *)gestureRecognizer
{
    [self.inputDelegate selectionWillChange:self];
    
    self.mouseLocation = [gestureRecognizer locationInView:self];
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan ||
        gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        
        if (self.isEditable) {
            if (!self.isEditing) {
                [self beginEditing];
            }
        }
        
        self.touchPhase = SETouchPhaseMoved;
        
        [self.textLayout setSelectionWithPoint:self.mouseLocation];
        
        [self moveMagnifierCaretToPoint:self.mouseLocation];
    } if (gestureRecognizer.state == UIGestureRecognizerStateEnded ||
          gestureRecognizer.state == UIGestureRecognizerStateCancelled ||
          gestureRecognizer.state == UIGestureRecognizerStateFailed) {
        self.touchPhase = SETouchPhaseNone;
        [self hideMagnifierCaret];
        
        [self finishSelecting];
    }
    
    [self selectionChanged];
    [self.inputDelegate selectionDidChange:self];
}

- (void)grabberMoved:(UIPanGestureRecognizer *)gestureRecognizer
{
    [self.inputDelegate selectionWillChange:self];
    
    SETextSelection *textSelection = self.textLayout.textSelection;
    if (!self.selectable || !textSelection) {
        return;
    }
    
    self.touchPhase = SETouchPhaseNone;
    self.mouseLocation = [gestureRecognizer locationInView:self];
    
    SESelectionGrabber *startGrabber = self.textSelectionView.startGrabber;
    SESelectionGrabber *endGrabber = self.textSelectionView.endGrabber;
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan ||
        gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        if (gestureRecognizer == self.textSelectionView.startGrabberGestureRecognizer) {
            self.textSelectionView.startGrabber.dragging = YES;
            
            [self.textLayout setSelectionStartWithFirstPoint:self.mouseLocation];
            [self moveMagnifierRangedToPoint:startGrabber.center];
        } else {
            [self.textLayout setSelectionEndWithPoint:self.mouseLocation];
            [self moveMagnifierRangedToPoint:endGrabber.center];
        }
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded ||
               gestureRecognizer.state == UIGestureRecognizerStateCancelled ||
               gestureRecognizer.state == UIGestureRecognizerStateFailed) {
        if (gestureRecognizer == self.textSelectionView.startGrabberGestureRecognizer) {
            startGrabber.dragging = NO;
        } else {
            endGrabber.dragging = NO;
        }
        
        [self hideMagnifierRanged];
        
        if (self.textLayout.textSelection) {
            [self finishSelecting];
        }
    }
    
    [self selectionChanged];
    [self.inputDelegate selectionDidChange:self];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self startLongPressTimer];
    
    UITouch *touch = touches.anyObject;
    self.mouseLocation = [touch locationInView:self];
    self.touchPhase = SETouchPhaseBegan;
    
    [self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self stopLongPressTimer];
    
    if (self.textSelectionView.selectionGestureRecognizer.state == UIGestureRecognizerStateBegan ||
        self.textSelectionView.selectionGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        self.touchPhase = SETouchPhaseMoved;
    } else {
        self.touchPhase = SETouchPhaseCancelled;
    }
    
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self stopLongPressTimer];
    
    UITouch *touch = touches.anyObject;
    self.mouseLocation = [touch locationInView:self];
    
    self.touchPhase = SETouchPhaseEnded;
    self.clickPoint = CGPointZero;
    
    if (self.longPressing) {
        self.longPressing = NO;
    } else {
        if (![self containsPointInSelection:self.mouseLocation]) {
            [self clearSelection];
            [self hideEditingMenu];
        } else {
            [self hideEditingMenu];
            [self showEditingMenu];
        }
        
        if ([self containsPointInTextFrame:self.mouseLocation]) {
            SELinkText *link = [self linkAtPoint:self.mouseLocation];
            if (link) {
                [self clickedOnLink:link];
                
                [self clearSelection];
                [self hideEditingMenu];
            }
        }
        
        if (self.isEditable) {
            if (!self.isEditing) {
                [self beginEditing];
            }
            [self updateCaretPositionToPoint:self.mouseLocation];
        }
    }
    
    [self setNeedsDisplay];
}

#pragma mark -

- (void)beginEditing
{
    if (!self.editing && !self.isFirstResponder) {
        BOOL shouldBeginEditing = YES;
        if ([self.delegate respondsToSelector:@selector(textViewShouldBeginEditing:)]) {
            shouldBeginEditing = [self.delegate textViewShouldBeginEditing:self];
        }
        if (self.isEditable && shouldBeginEditing) {
            self.editing = YES;
            [self becomeFirstResponder];
        }
    }
}

- (void)updateCaretPosition
{
    [self.inputDelegate selectionWillChange:self];
    
    NSRange selectedRange = self.selectedRange;
    self.caretView.frame = [self caretRectForPosition:[SETextPosition positionWithIndex:selectedRange.location + selectedRange.length]];
    
    [self selectionChanged];
    
    [self.inputDelegate selectionDidChange:self];
}

- (void)updateCaretPositionToPoint:(CGPoint)point
{
    [self.inputDelegate selectionWillChange:self];
    
    if (!self.textLayout.textSelection) {
        self.textLayout.textSelection = [[SETextSelection alloc] init];
    }
    
    SETextPosition *position = (SETextPosition *)[self closestPositionToPoint:point];
    NSUInteger index = position.index;
    if (index == NSNotFound) {
        index = self.text.length;
    }
    if (self.text.length == 0) {
        index = 0;
    }
    
    NSRange selectedRange = NSMakeRange(index, 0);
    self.caretView.frame = [self caretRectForPosition:[SETextPosition positionWithIndex:selectedRange.location + selectedRange.length]];
    
    self.textLayout.textSelection.selectedRange = selectedRange;
    [self selectionChanged];
    
    [self.inputDelegate selectionDidChange:self];
}

- (void)showEditingMenu
{
    if (!self.isFirstResponder && !self.textSelectionView.isFirstResponder) {
        [self.textSelectionView becomeFirstResponder];
    }
    
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    menuController.arrowDirection = UIMenuControllerArrowDefault;
    [menuController setTargetRect:[self editingMenuRectForSelection] inView:self];
    
    [menuController setMenuVisible:YES animated:YES];
}

- (void)hideEditingMenu
{
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    [menuController setMenuVisible:NO animated:YES];
    
    if (self.textSelectionView.isFirstResponder) {
        [self.textSelectionView resignFirstResponder];
    }
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

#else
#pragma mark - OS X mouse events

- (CGPoint)mouseLocationOnEvent:(NSEvent *)theEvent
{
    CGPoint locationInWindow = [theEvent locationInWindow];
    CGPoint location = [self convertPoint:locationInWindow fromView:nil];
    
    return location;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [self startLongPressTimer];
    
    self.mouseLocation = [self mouseLocationOnEvent:theEvent];
    
    if (theEvent.clickCount == 2) {
        self.touchPhase = SETouchPhaseMoved;
        [self.textLayout setSelectionWithPoint:self.mouseLocation];
    } else if ([self containsPointInTextFrame:self.mouseLocation]) {
        self.touchPhase = SETouchPhaseBegan;
        [self.textLayout setSelectionStartWithPoint:self.mouseLocation];
    }
    
    [self selectionChanged];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    self.mouseLocation = [self mouseLocationOnEvent:theEvent];
    
    self.touchPhase = SETouchPhaseMoved;
    
    [self.textLayout setSelectionEndWithNearestPoint:self.mouseLocation];
    
    [self selectionChanged];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [self stopLongPressTimer];
    
    self.mouseLocation = [self mouseLocationOnEvent:theEvent];
    self.clickPoint = CGPointZero;
    
    self.touchPhase = SETouchPhaseEnded;
    
    if (self.longPressing) {
        self.longPressing = NO;
    } else {
        if ([self containsPointInTextFrame:self.mouseLocation]) {
            SELinkText *link = [self linkAtPoint:self.mouseLocation];
            if (link) {
                [self clickedOnLink:link];
            }
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

- (NSMenu *)menuForEvent:(NSEvent *)event
{
    if (self.textLayout.textSelection) {
        NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
        [menu addItemWithTitle:NSLocalizedString(@"Cut", nil) action:@selector(cut:) keyEquivalent:@""];
        [menu addItemWithTitle:NSLocalizedString(@"Copy", nil) action:@selector(copy:) keyEquivalent:@""];
        [menu addItemWithTitle:NSLocalizedString(@"Paste", nil) action:@selector(paste:) keyEquivalent:@""];
        [menu addItem:[NSMenuItem separatorItem]];
        [menu addItemWithTitle:NSLocalizedString(@"Select All", nil) action:@selector(selectAll:) keyEquivalent:@""];
        
        return [[[NSTextView alloc] init] menuForEvent:event];
    }
    
    return nil;
}

- (void)quickLookWithEvent:(NSEvent *)event
{
    if (!self.textLayout.textSelection) {
        self.mouseLocation = [self mouseLocationOnEvent:event];
        [self.textLayout setSelectionWithPoint:self.mouseLocation];
    }
    
    CGRect rect = [self rectOfFirstLineInSelectionRect];
    [self showDefinitionForAttributedString:self.selectedAttributedText atPoint:rect.origin];
}

- (CGRect)rectOfFirstLineInSelectionRect
{
    SETextSelection *textSelection = self.textLayout.textSelection;
    if (!textSelection) {
        return CGRectZero;
    }
    
    for (SELineLayout *lineLayout in self.textLayout.lineLayouts) {
        CGRect selectionRect = [lineLayout rectOfStringWithRange:textSelection.selectedRange];
        if (!CGRectIsEmpty(selectionRect)) {
            return selectionRect;
        }
    }
    
    return CGRectZero;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)resignFirstResponder
{
    [self clearSelection];
    self.editing = NO;
    
    [self setNeedsDisplayInRect:self.bounds];
    
    return YES;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if (menuItem.action == @selector(copy:)) {
        return self.selectedRange.length > 0;
    }
    if (menuItem.action == @selector(cut:) ||
        menuItem.action == @selector(paste:) ||
        menuItem.action == @selector(delete:)) {
        return NO;
    }
    
    return YES;
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
    if (self.textLayout.textSelection) {
        if ((theEvent.modifierFlags & NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask) {
            if ([theEvent.characters isEqualToString:@"c"]) {
                [self copy:nil];
                return YES;
            }
            if ([theEvent.characters isEqualToString:@"a"]) {
                [self selectAll:nil];
                return YES;
            }
        }
    }
    
    return [super performKeyEquivalent:theEvent];
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

- (IBAction)copy:(id)sender
{
#if TARGET_OS_IPHONE
    if (self.selectedText.length > 0) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = self.selectedText;
    }
#else
    if (self.selectedAttributedText.length > 0) {
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        [pasteboard writeObjects:@[self.selectedText]];
    }
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

- (BOOL)canResignFirstResponder
{
    return YES;
}

#if TARGET_OS_IPHONE
#pragma mark UITextInput methods

- (NSString *)textInRange:(UITextRange *)range
{
    NSLog(@"%s", __func__);
    SETextRange *r = (SETextRange *)range;
    if (r.range.location == NSNotFound) {
        return nil;
    }
    NSString *text = [self.text substringWithRange:r.range];
    NSLog(@"%@ %@", r, text);
    return text;
}

- (void)replaceRange:(UITextRange *)range withText:(NSString *)text
{
    NSLog(@"%s", __func__);
    SETextRange *r = (SETextRange *)range;
    
    NSRange selectedRange = self.selectedRange;
    if (r.range.location + r.range.length <= selectedRange.location) {
        selectedRange.location -= r.range.length - text.length;
    } else {
        // Need to also deal with overlapping ranges.  Not addressed
		// in this simplified sample.
    }
    
    NSMutableString *editingText = self.editingText;
    [editingText replaceCharactersInRange:r.range withString:text];
    
    self.text = editingText.copy;
    self.textLayout.textSelection.selectedRange = selectedRange;
    
    [self selectionChanged];
}

- (UITextRange *)selectedTextRange
{
    if (!self.textLayout.textSelection) {
        return nil;
    }
    SETextRange *textRange = [SETextRange rangeWithNSRange:self.textLayout.textSelection.selectedRange];
    NSLog(@"selectedTextRange: %@", textRange);
    return textRange;
}

- (void)setSelectedTextRange:(UITextRange *)selectedTextRange
{
    NSLog(@"%s", __func__);
    SETextRange *textRange = (SETextRange *)selectedTextRange;
    self.textLayout.textSelection.selectedRange = textRange.range;
    
    [self selectionChanged];
}

- (UITextRange *)markedTextRange
{
    NSLog(@"%s", __func__);
    if (self.textLayout.markedTextRange.location == NSNotFound) {
        return nil;
    }
    return [SETextRange rangeWithNSRange:self.textLayout.markedTextRange];
}

- (void)setMarkedText:(NSString *)markedText selectedRange:(NSRange)selectedRange
{
    NSLog(@"%s", __func__);
    NSLog(@"%@ %@", markedText, NSStringFromRange(selectedRange));
    if (markedText.length == 0 && selectedRange.length == 0) {
        return;
    }
    
    NSRange selectedNSRange = self.selectedRange;
    NSRange markedTextRange = self.textLayout.markedTextRange;
    
    NSMutableString *editingText = self.editingText;
    
    if (markedTextRange.location != NSNotFound) {
        if (!markedText) {
            markedText = @"";
        }
        
        [editingText replaceCharactersInRange:markedTextRange withString:markedText];
        markedTextRange.length = markedText.length;
    } else if (selectedNSRange.length > 0) {
        [editingText replaceCharactersInRange:selectedNSRange withString:markedText];
        markedTextRange.location = selectedNSRange.location;
        markedTextRange.length = markedText.length;
    } else {
        [editingText insertString:markedText atIndex:selectedNSRange.location];
        markedTextRange.location = selectedNSRange.location;
        markedTextRange.length = markedText.length;
    }
	
    selectedNSRange = NSMakeRange(markedTextRange.location + selectedRange.location, selectedRange.length);
    
    self.text = editingText.copy;
    self.textLayout.markedTextRange = markedTextRange;
    self.textLayout.textSelection.selectedRange = selectedNSRange;
    
    [self updateLayout];
    [self updateCaretPosition];
}

- (void)unmarkText
{
    NSLog(@"%s", __func__);
    NSRange markedTextRange = self.textLayout.markedTextRange;
    NSLog(@"%@", self.text);
    
    if (markedTextRange.location == NSNotFound) {
        return;
    }
    
    markedTextRange.location = NSNotFound;
    self.textLayout.markedTextRange = markedTextRange;
    
//    [self updateLayout];
//    [self updateCaretPosition];
}

- (UITextPosition *)beginningOfDocument
{
    NSLog(@"%s", __func__);
    SETextPosition *position = [SETextPosition positionWithIndex:0];
    NSLog(@"%@", position);
    return position;
}

- (UITextPosition *)endOfDocument
{
    NSLog(@"%s", __func__);
    SETextPosition *position = [SETextPosition positionWithIndex:self.text.length];
    NSLog(@"%@", position);
    return position;
}

- (UITextRange *)textRangeFromPosition:(UITextPosition *)fromPosition toPosition:(UITextPosition *)toPosition
{
    NSLog(@"%s", __func__);
    SETextPosition *from = (SETextPosition *)fromPosition;
    SETextPosition *to = (SETextPosition *)toPosition;
    NSLog(@"%@ %@", from, to);
    NSLog(@"%d", abs(to.index - from.index));
    NSRange range = NSMakeRange(from.index, abs(to.index - from.index));
    NSLog(@"%@", NSStringFromRange(range));
    return [SETextRange rangeWithNSRange:range];
}

- (UITextPosition *)positionFromPosition:(UITextPosition *)position offset:(NSInteger)offset
{
    NSLog(@"%s", __func__);
    SETextPosition *pos = (SETextPosition *)position;
    NSInteger end = pos.index + offset;
    if (end > self.text.length || end < 0) {
        return nil;
    }
    
    return [SETextPosition positionWithIndex:end];
}

- (UITextPosition *)positionFromPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction offset:(NSInteger)offset
{
    NSLog(@"%s", __func__);
    SETextPosition *pos = (SETextPosition *)position;
    NSInteger newPos = pos.index;
    
    switch (direction) {
        case UITextLayoutDirectionRight:
            newPos += offset;
            break;
        case UITextLayoutDirectionLeft:
            newPos -= offset;
            break;
        case UITextLayoutDirectionUp:
        case UITextLayoutDirectionDown:
            break;
    }
	
    if (newPos < 0) {
        newPos = 0;
    }
    
    if (newPos > _text.length) {
        newPos = _text.length;
    }
    
    return [SETextPosition positionWithIndex:newPos];
}

- (NSComparisonResult)comparePosition:(UITextPosition *)position toPosition:(UITextPosition *)other
{
    NSLog(@"%s", __func__);
    SETextPosition *pos = (SETextPosition *)position;
    SETextPosition *o = (SETextPosition *)other;
    
    if (pos.index == o.index) {
        return NSOrderedSame;
    } if (pos.index < o.index) {
        return NSOrderedAscending;
    } else {
        return NSOrderedDescending;
    }
}

- (NSInteger)offsetFromPosition:(UITextPosition *)from toPosition:(UITextPosition *)toPosition
{
    NSLog(@"%s", __func__);
    SETextPosition *f = (SETextPosition *)from;
    SETextPosition *t = (SETextPosition *)toPosition;
    NSLog(@"%@ %@", f, t);
    if (f.index == NSUIntegerMax || t.index == NSUIntegerMax) {
        return 0;
    }
    return t.index - f.index;
}

- (id<UITextInputTokenizer>)tokenizer
{
    NSLog(@"%s", __func__);
    if (!_tokenizer) {
        _tokenizer = [[UITextInputStringTokenizer alloc] initWithTextInput:self];
    }
    
    return _tokenizer;
}

/* Layout questions. */
- (UITextPosition *)positionWithinRange:(UITextRange *)range farthestInDirection:(UITextLayoutDirection)direction
{
    NSLog(@"%s", __func__);
    SETextRange *r = (SETextRange *)range;
    NSInteger pos = r.range.location;
    
    switch (direction) {
        case UITextLayoutDirectionUp:
        case UITextLayoutDirectionLeft:
            pos = r.range.location;
            break;
        case UITextLayoutDirectionRight:
        case UITextLayoutDirectionDown:
            pos = r.range.location + r.range.length;
            break;
    }
    
    return [SETextPosition positionWithIndex:pos];
}

- (UITextRange *)characterRangeByExtendingPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction
{
    NSLog(@"%s", __func__);
    SETextPosition *pos = (SETextPosition *)position;
    NSRange result = NSMakeRange(pos.index, 1);
    
    switch (direction) {
        case UITextLayoutDirectionUp:
        case UITextLayoutDirectionLeft:
            result = NSMakeRange(pos.index - 1, 1);
            break;
        case UITextLayoutDirectionRight:
        case UITextLayoutDirectionDown:
            result = NSMakeRange(pos.index, 1);
            break;
    }
    
    return [SETextRange rangeWithNSRange:result];
}

/* Writing direction */
- (UITextWritingDirection)baseWritingDirectionForPosition:(UITextPosition *)position inDirection:(UITextStorageDirection)direction
{
    NSLog(@"%s", __func__);
    return UITextWritingDirectionLeftToRight;
}

- (void)setBaseWritingDirection:(UITextWritingDirection)writingDirection forRange:(UITextRange *)range
{
    NSLog(@"%s", __func__);
    // Not supported.
}

/* Geometry used to provide, for example, a correction rect. */
- (CGRect)firstRectForRange:(UITextRange *)range
{
    NSLog(@"%s", __func__);
    SETextRange *r = (SETextRange *)range;
    
    for (SELineLayout *lineLayout in self.textLayout.lineLayouts) {
        CGRect rect = [lineLayout rectOfStringWithRange:r.range];
        if (!CGRectIsEmpty(rect)) {
            CGFloat lineSpacing = self.lineSpacing;
            rect.origin.y -= lineSpacing;
            rect.size.height += lineSpacing;
            
            return rect;
        }
    }
    
    return CGRectNull;
}

- (CGRect)caretRectForPosition:(UITextPosition *)position
{
    NSLog(@"%s", __func__);
    SETextPosition *pos = (SETextPosition *)position;
    
    if (self.text.length == 0) {
        CGPoint origin = CGPointMake(CGRectGetMinX(self.bounds), CGRectGetMinY(self.bounds) - self.font.leading);
        return CGRectMake(origin.x, origin.y + fabs(self.font.descender) + fabs(self.font.ascender), CGRectGetWidth(self.caretView.bounds), self.font.ascender + fabs(self.font.descender));
    }
    
    CGRect rect;
    NSUInteger index = pos.index;
    if (index < self.text.length && [[self.text substringWithRange:NSMakeRange(index - 1, 1)] isEqualToString:@"\n"]) {
        rect = [self.textLayout rectOfStringForIndex:index + 1];
    } else {
        rect = [self.textLayout rectOfStringForIndex:index];
        rect.origin.x += CGRectGetWidth(rect);
    }
    
    CGFloat lineSpacing = self.lineSpacing;
    rect.origin.x -= CGRectGetWidth(self.caretView.bounds);
    rect.origin.y -= lineSpacing;
    rect.size.width = CGRectGetWidth(self.caretView.bounds);
    rect.size.height += lineSpacing;
    
    if (CGRectGetMinX(rect) < 0.0f) {
        rect.origin.x = 0.0f;
    }
    
    return rect;
}

- (NSArray *)selectionRectsForRange:(UITextRange *)range
{
    NSLog(@"%s", __func__);
    // Not implemented yet.
    return nil;
}

/* Hit testing. */
- (UITextPosition *)closestPositionToPoint:(CGPoint)point
{
    CFIndex index = [self.textLayout stringIndexForNearestPosition:point];
    return [SETextPosition positionWithIndex:index];
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point withinRange:(UITextRange *)range
{
    NSLog(@"%s", __func__);
    CFIndex index = [self stringIndexAtPoint:point];
    SETextRange *r = (SETextRange *)range;
    if (index >= r.range.location && index <= r.range.location + r.range.length) {
        return [SETextPosition positionWithIndex:index];
    }
    
    return nil;
}

- (UITextRange *)characterRangeAtPoint:(CGPoint)point
{
    NSLog(@"%s", __func__);
    CFIndex index = [self stringIndexAtPoint:point];
    CFIndex length = 1;
    
    if (index < 0) {
        index = 0;
    }
    if (index > self.text.length) {
        index = self.text.length;
        length = 0;
    }
    
    return [SETextRange rangeWithNSRange:NSMakeRange(index, length)];
}

- (BOOL)shouldChangeTextInRange:(UITextRange *)range replacementText:(NSString *)text
{
    NSLog(@"%s", __func__);
    NSLog(@"%@ %@", NSStringFromRange(((SETextRange *)range).range), text);
    return YES;
}

- (NSDictionary *)textStylingAtPosition:(UITextPosition *)position inDirection:(UITextStorageDirection)direction
{
    NSLog(@"%s", __func__);
    return @{UITextInputTextFontKey: self.font};
}

#pragma mark -
#pragma mark UIKeyInput methods

- (BOOL)hasText
{
    NSLog(@"%s", __func__);
    return self.text.length > 0;
}

- (void)insertText:(NSString *)text
{
    NSLog(@"%s", __func__);
    NSRange selectedNSRange = self.textLayout.textSelection.selectedRange;
    SETextRange *markedTextRange = (SETextRange *)self.markedTextRange;
    NSRange markedTextNSRange;
    if (markedTextRange) {
        markedTextNSRange = markedTextRange.range;
    } else {
        markedTextNSRange = NSMakeRange(NSNotFound, 0);
    }
    
    NSMutableString *editingText = self.editingText;
    
    if (markedTextRange && markedTextNSRange.location != NSNotFound) {
        [editingText replaceCharactersInRange:markedTextNSRange withString:text];
        selectedNSRange.location = markedTextNSRange.location + text.length;
        selectedNSRange.length = 0;
        markedTextNSRange = NSMakeRange(NSNotFound, 0);
    } else if (selectedNSRange.length > 0) {
        [editingText replaceCharactersInRange:selectedNSRange withString:text];
        selectedNSRange.length = 0;
        selectedNSRange.location += text.length;
    } else {
        [editingText insertString:text atIndex:selectedNSRange.location];
        selectedNSRange.location += text.length;
    }
    
    self.text = editingText.copy;
    self.textLayout.markedTextRange = markedTextNSRange;
    self.textLayout.textSelection.selectedRange = selectedNSRange;
    
    [self updateLayout];
    [self updateCaretPosition];
}

- (void)deleteBackward
{
    NSLog(@"%s", __func__);
    NSRange selectedNSRange = self.textLayout.textSelection.selectedRange;
    SETextRange *markedTextRange = (SETextRange *)self.markedTextRange;
    NSRange markedTextNSRange;
    if (markedTextRange) {
        markedTextNSRange = markedTextRange.range;
    } else {
        markedTextNSRange = NSMakeRange(NSNotFound, 0);
    }
    
    NSMutableString *editingText = self.editingText;
    
    if (markedTextRange && markedTextNSRange.location != NSNotFound) {
        [editingText deleteCharactersInRange:markedTextNSRange];
        selectedNSRange.location = markedTextNSRange.location;
        selectedNSRange.length = 0;
        markedTextNSRange = NSMakeRange(NSNotFound, 0);
    } else if (selectedNSRange.length > 0) {
        [editingText deleteCharactersInRange:selectedNSRange];
        selectedNSRange.length = 0;
    } else if (selectedNSRange.location > 0) {
        selectedNSRange.location--;
        selectedNSRange.length = 1;
        [editingText deleteCharactersInRange:selectedNSRange];
        selectedNSRange.length = 0;
    }
    
    self.text = editingText.copy;
    self.textLayout.markedTextRange = markedTextNSRange;
    self.textLayout.textSelection.selectedRange = selectedNSRange;
    
    [self updateLayout];
    [self updateCaretPosition];
}
#endif

@end
