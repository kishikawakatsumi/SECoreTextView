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
@property (strong, nonatomic) UIImageView *dotImageView;

@end

@implementation SESelectionGrabber

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.dotImage = [UIImage imageNamed:@"SECoreTextView.bundle/kb-drag-dot"];
        
        self.dotImageView = [[UIImageView alloc] initWithImage:self.dotImage];
        
        [self addSubview:self.dotImageView];
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    CGRect dotImageFrame = self.dotImageView.bounds;
    if (self.dotMetric == SESelectionGrabberDotMetricTop) {
        dotImageFrame.origin = CGPointMake(ceilf((CGRectGetWidth(self.bounds) - self.dotSize.width) / 2 - 2.0f),
                                           -12.0f);
    } else {
        dotImageFrame.origin = CGPointMake(ceilf((CGRectGetWidth(self.bounds) - self.dotSize.width) / 2 + 2.0f),
                                           CGRectGetHeight(self.bounds) - 6.0f);
    }
    self.dotImageView.frame = dotImageFrame;
}

- (CGSize)dotSize
{
    return CGSizeMake(14.0f, 12.0f);
}

@end
#endif
