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

@interface SETextView : NSView <NSTextInputClient>

@property (nonatomic, weak) IBOutlet id<SETextViewDelegate> delegate;

@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSAttributedString *attributedText;

@property (nonatomic) NSFont *font;
@property (nonatomic) NSColor *textColor;
@property (nonatomic) NSColor *highlightedTextColor;
@property (nonatomic) NSTextAlignment textAlignment;
@property (nonatomic) CGFloat lineSpacing;
@property (nonatomic) CGFloat lineHeight;
@property (nonatomic) CGFloat paragraphSpacing;

@property (nonatomic) NSColor *selectedTextBackgroundColor;
@property (nonatomic) NSColor *linkHighlightColor;
@property (nonatomic) NSColor *linkRolloverEffectColor;

@property (nonatomic, readonly) CGRect layoutFrame;

@property (nonatomic, getter = isHighlighted) BOOL highlighted;
@property (nonatomic, getter = isSelectable) BOOL selectable;
#if TARGET_OS_IPHONE
@property (nonatomic) BOOL showsEditingMenuAutomatically;
#endif

@property (nonatomic, readonly) NSRange selectedRange;
@property (nonatomic, readonly) NSString *selectedText;
@property (nonatomic, readonly) NSAttributedString *selectedAttributedText;

@property (nonatomic) NSTimeInterval minimumLongPressDuration;

@property (nonatomic, getter = isEditable) BOOL editable;
@property (nonatomic, getter = isEditing) BOOL editing;

@property (readwrite) UIView *inputView;
@property (readwrite) UIView *inputAccessoryView;

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

- (BOOL)textViewShouldBeginEditing:(SETextView *)textView;
- (void)textViewDidBeginEditing:(SETextView *)textView;
- (BOOL)textViewShouldEndEditing:(SETextView *)textView;
- (void)textViewDidEndEditing:(SETextView *)textView;

@end
