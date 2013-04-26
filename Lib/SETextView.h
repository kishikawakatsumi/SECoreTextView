//
//  SETextView.h
//  SECoreTextView
//
//  Created by kishikawa katsumi on 2013/04/20.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import "SECompatibility.h"

typedef void(^SETextAttachmentDrawBlock)(CGRect rect);

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

@property (assign, nonatomic) NSEdgeInsets edgePadding;

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
@property (strong, nonatomic, readonly) NSString *selectedAttributedText;

- (id)initWithFrame:(CGRect)frame;
- (id)initWithFrame:(CGRect)frame topPadding:(CGFloat)topPadding leftPadding:(CGFloat)leftPadding;
- (id)initWithFrame:(CGRect)frame edgePadding:(NSEdgeInsets)edgePadding;

+ (CGRect)frameRectWithAttributtedString:(NSAttributedString *)attributedString
                          constraintSize:(CGSize)constraintSize;
+ (CGRect)frameRectWithAttributtedString:(NSAttributedString *)attributedString
                          constraintSize:(CGSize)constraintSize
                             edgePadding:(NSEdgeInsets)edgePadding;
+ (CGRect)frameRectWithAttributtedString:(NSAttributedString *)attributedString
                          constraintSize:(CGSize)constraintSize
                             lineSpacing:(CGFloat)lineSpacing;
+ (CGRect)frameRectWithAttributtedString:(NSAttributedString *)attributedString
                          constraintSize:(CGSize)constraintSize
                             edgePadding:(NSEdgeInsets)edgePadding
                             lineSpacing:(CGFloat)lineSpacing;
+ (CGRect)frameRectWithAttributtedString:(NSAttributedString *)attributedString
                          constraintSize:(CGSize)constraintSize
                                    font:(NSFont *)font;
+ (CGRect)frameRectWithAttributtedString:(NSAttributedString *)attributedString
                          constraintSize:(CGSize)constraintSize
                                    font:(NSFont *)font
                             lineSpacing:(CGFloat)lineSpacing;
+ (CGRect)frameRectWithAttributtedString:(NSAttributedString *)attributedString
                          constraintSize:(CGSize)constraintSize
                                    font:(NSFont *)font
                             edgePadding:(NSEdgeInsets)edgePadding;
+ (CGRect)frameRectWithAttributtedString:(NSAttributedString *)attributedString
                          constraintSize:(CGSize)constraintSize
                                    font:(NSFont *)font
                             edgePadding:(NSEdgeInsets)edgePadding
                             lineSpacing:(CGFloat)lineSpacing;

- (void)addObject:(id)object size:(CGSize)size atIndex:(NSInteger)index;
- (void)addObject:(id)object size:(CGSize)size replaceRange:(NSRange)range;

- (void)clearSelection;

@end

@protocol SETextViewDelegate <NSObject>

@optional
- (BOOL)textView:(SETextView *)aTextView clickedOnLink:(SELinkText *)link atIndex:(NSUInteger)charIndex;
- (void)textViewDidChangeSelection:(SETextView *)aTextView;
- (void)textViewDidEndSelecting:(SETextView *)aTextView;

@end
