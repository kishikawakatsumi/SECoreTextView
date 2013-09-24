//
//  SETextEditingCaret.m
//  CoreTextEditor
//
//  Created by kishikawa katsumi on 2013/09/24.
//  Copyright (c) 2013年 kishikawa katsumi. All rights reserved.
//

#if TARGET_OS_IPHONE
#import "SETextEditingCaret.h"
#import "SEConstants.h"

static const NSTimeInterval SETextEditingCaretInitialBlinkDelay = 0.7;
static const NSTimeInterval SETextEditingCaretBlinkRate = 0.6;
static const NSTimeInterval SETextEditingCaretBlinkAnimationDuration = 0.1;

@interface SETextEditingCaret ()

@property (nonatomic) NSTimer *blinkTimer;

@end

@implementation SETextEditingCaret

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [SEConstants caretColor];
        self.userInteractionEnabled = NO;
    }
    
    return self;
}

- (void)blink
{
    [UIView animateWithDuration:SETextEditingCaretBlinkAnimationDuration delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.alpha = !self.alpha;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)didMoveToSuperview
{
    self.alpha = 1.0f;
    
    if (self.superview) {
        self.blinkTimer = [NSTimer timerWithTimeInterval:SETextEditingCaretBlinkRate target:self selector:@selector(blink) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.blinkTimer forMode:NSRunLoopCommonModes];
        [self delayBlink];
    } else {
        [self.blinkTimer invalidate];
        self.blinkTimer = nil;
    }
}

- (void)dealloc
{
    [_blinkTimer invalidate];
}

- (void)delayBlink
{
    self.alpha = 1.0f;
    self.blinkTimer.fireDate = [NSDate dateWithTimeIntervalSinceNow:SETextEditingCaretInitialBlinkDelay];
}

@end
#endif
