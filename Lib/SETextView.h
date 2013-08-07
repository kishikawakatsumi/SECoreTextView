//
//  SETextView.h
//  SECoreTextView
//
//  Created by kishikawa katsumi on 2013/04/20.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import "SELinkText.h"
#import "SECompatibility.h"
#import "NSMutableAttributedString+Helper.h"

typedef void(^SETextAttachmentDrawingBlock)(CGRect rect, CGContextRef context);

typedef NS_ENUM(NSUInteger, SETextAttachmentDrawingOptions) {
    SETextAttachmentDrawingOptionNone = 0,
    SETextAttachmentDrawingOptionNewLine  = 1 << 0
};

@protocol SETextViewDelegate;

@class SELinkText;

@interface SETextView : NSView

@property (weak, nonatomic) IBOutlet id<SETextViewDelegate> delegate;

@property (copy, nonatomic) NSString *text;
@property (copy, nonatomic) NSAttributedString *attributedText;

@property (strong, nonatomic) NSFont *font;
@property (strong, nonatomic) NSColor *textColor;
@property (strong, nonatomic) NSColor *highlightedTextColor;
@property (assign, nonatomic) NSTextAlignment textAlignment;
@property (assign, nonatomic) CGFloat lineSpacing;
@property (assign, nonatomic) CGFloat lineHeight;
@property (assign, nonatomic) CGFloat paragraphSpacing;

@property (strong, nonatomic) NSColor *selectedTextBackgroundColor;
@property (strong, nonatomic) NSColor *linkHighlightColor;
@property (strong, nonatomic) NSColor *linkRolloverEffectColor;

@property (assign, nonatomic, readonly) CGRect layoutFrame;

@property (assign, nonatomic, getter = isHighlighted) BOOL highlighted;
@property (assign, nonatomic, getter = isSelectable) BOOL selectable;
#if TARGET_OS_IPHONE
@property (assign, nonatomic) BOOL showsEditingMenuAutomatically;
#endif

@property (assign, nonatomic, readonly) NSRange selectedRange;
@property (strong, nonatomic, readonly) NSString *selectedText;
@property (strong, nonatomic, readonly) NSAttributedString *selectedAttributedText;

@property (assign, nonatomic) NSTimeInterval minimumLongPressDuration;

- (id)initWithFrame:(CGRect)frame;

+ (CGRect)frameRectWithAttributtedString:(NSAttributedString *)attributedString
                          constraintSize:(CGSize)constraintSize;
+ (CGRect)frameRectWithAttributtedString:(NSAttributedString *)attributedString
                          constraintSize:(CGSize)constraintSize
                             lineSpacing:(CGFloat)lineSpacing;
+ (CGRect)frameRectWithAttributtedString:(NSAttributedString *)attributedString
                          constraintSize:(CGSize)constraintSize
                             lineSpacing:(CGFloat)lineSpacing
                                    font:(NSFont *)font;

- (void)addObject:(id)object size:(CGSize)size atIndex:(NSInteger)index;
- (void)addObject:(id)object size:(CGSize)size replaceRange:(NSRange)range;

- (void)clearSelection;

@end

@protocol SETextViewDelegate <NSObject>

@optional
- (BOOL)textView:(SETextView *)textView clickedOnLink:(SELinkText *)link atIndex:(NSUInteger)charIndex;
- (BOOL)textView:(SETextView *)textView longPressedOnLink:(SELinkText *)link atIndex:(NSUInteger)charIndex;
- (void)textViewDidChangeSelection:(SETextView *)textView;
- (void)textViewDidEndSelecting:(SETextView *)textView;

@end
