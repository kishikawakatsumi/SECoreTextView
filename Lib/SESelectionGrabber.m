//
//  SESelectionGrabber.m
//  SECoreTextView-iOS
//
//  Created by kishikawa katsumi on 2013/04/23.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#if TARGET_OS_IPHONE
#import "SESelectionGrabber.h"

@interface SESelectionGrabber ()

@property (strong, nonatomic) UIImage *dotImage;

@end

@implementation SESelectionGrabber

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.dotImage = [UIImage imageNamed:@"kb-drag-dot"];
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    [self.dotImage drawAtPoint:CGPointMake(ceilf((CGRectGetWidth(self.bounds) - self.dotSize.width) / 2),
                                           ceilf((CGRectGetHeight(self.bounds) - self.dotSize.height) / 2))];
}

- (CGSize)dotSize
{
    return CGSizeMake(14.0f, 12.0f);
}

@end
#endif
