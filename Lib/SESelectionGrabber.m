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

- (id)init
{
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        self.dotImage = [UIImage imageNamed:@"kb-drag-dot"];
    }
    return self;
}

- (CGSize)dotSize
{
    return CGSizeMake(14.0f, 12.0f);
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    [self.dotImage drawAtPoint:CGPointMake(ceilf((CGRectGetWidth(self.bounds) - self.dotSize.width) / 2),
                                           ceilf((CGRectGetHeight(self.bounds) - self.dotSize.height) / 2))];
}

@end
#endif
