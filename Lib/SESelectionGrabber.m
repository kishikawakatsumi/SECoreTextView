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
        self.dotImage = [UIImage imageNamed:@"kb-drag-dot"];
        
        CGRect initialFrame = self.frame;
        initialFrame.size.width = self.dotSize.width;
        self.frame = initialFrame;
    }
    return self;
}

- (CGSize)dotSize
{
    return self.dotImage.size;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    [self.dotImage drawAtPoint:CGPointZero];
}

@end
#endif
