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

@property(nonatomic, getter=isHighlighted) BOOL highlighted;
@property(nonatomic, getter=isSelectable) BOOL selectable;

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
                             edgePadding:(NSEdgeInsets)edgePadding
                             lineSpacing:(CGFloat)lineSpacing;

- (void)clearSelection;

@end

@protocol SETextViewDelegate <NSObject>

@optional
//- (NSURL *)textView:(SETextView *)textView URLForContentsOfTextAttachment:(NSTextAttachment *)textAttachment atIndex:(NSUInteger)charIndex;
- (BOOL)textView:(SETextView *)aTextView clickedOnLink:(SELinkText *)link atIndex:(NSUInteger)charIndex;
//- (NSRange)textView:(SETextView *)aTextView willChangeSelectionFromCharacterRange:(NSRange)oldSelectedCharRange toCharacterRange:(NSRange)newSelectedCharRange;
//- (NSArray *)textView:(SETextView *)aTextView willChangeSelectionFromCharacterRanges:(NSArray *)oldSelectedCharRanges toCharacterRanges:(NSArray *)newSelectedCharRanges;
//- (void)textViewDidChangeSelection:(SETextView *)aNotification;

@end
