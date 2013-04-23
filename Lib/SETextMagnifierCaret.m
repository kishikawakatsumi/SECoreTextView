//
//  SETextMagnifierCaret.m
//  SECoreTextView-iOS
//
//  Created by kishikawa katsumi on 2013/04/23.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#if TARGET_OS_IPHONE
#import "SETextMagnifierCaret.h"

@interface SETextMagnifierCaret ()

@property (strong, nonatomic) UIView *magnifyToView;
@property (assign, nonatomic) CGPoint touchPoint;

@property (strong, nonatomic) UIImage *mask;
@property (strong, nonatomic) UIImage *loupe;
@property (strong, nonatomic) UIImage *cache;

@end

@implementation SETextMagnifierCaret

- (id)initWithFrame:(CGRect)frame
{
	UIImage *mask = [UIImage imageNamed:@"kb-loupe-mask"];
	if (self = [super initWithFrame:CGRectMake(0.0f, 0.0f, mask.size.width, mask.size.height)]) {
		self.backgroundColor = [UIColor clearColor];
		self.mask = mask;
		self.loupe = [UIImage imageNamed:@"kb-loupe-hi"];
	}
	return self;
}

- (void)setTouchPoint:(CGPoint)point
{
	_touchPoint = point;
    self.center = CGPointMake(point.x, point.y - 65);
}

- (void)showInView:(UIView *)view atPoint:(CGPoint)point
{
    [view addSubview:self];
    
    self.magnifyToView = view;
    self.touchPoint = point;
    
    CGRect frame = self.frame;
    CGPoint center = self.center;
    
    CGRect startFrame = self.frame;
    startFrame.size = CGSizeZero;
    self.frame = startFrame;
    
    CGPoint startPosition = self.center;
    startPosition.x += frame.size.width / 2;
    startPosition.y += frame.size.height;
    self.center = startPosition;
    
    [UIView animateWithDuration:0.15
                          delay:0.0
                        options:0
                     animations:^
     {
         self.frame = frame;
         self.center = center;
     }
                     completion:NULL];
}

- (void)moveToPoint:(CGPoint)point
{
	self.touchPoint = point;
    [self setNeedsDisplay];
}

- (void)hide
{
    CGRect bounds = self.bounds;
    bounds.size = CGSizeZero;
    
    CGPoint position = self.touchPoint;
    
    [UIView animateWithDuration:0.15
                          delay:0.0
                        options:0
                     animations:^
     {
         self.bounds = bounds;
         self.center = position;
     }
                     completion:^(BOOL finished)
     {
         self.magnifyToView = nil;
         [self removeFromSuperview];
     }];
}

- (void)drawRect:(CGRect)rect
{
	UIGraphicsBeginImageContext(self.magnifyToView.bounds.size);
	[self.magnifyToView.layer renderInContext:UIGraphicsGetCurrentContext()];
	self.cache = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	CGImageRef imageRef = self.cache.CGImage;
	CGImageRef maskRef = self.mask.CGImage;
	CGImageRef overlay = self.loupe.CGImage;
	CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
										CGImageGetHeight(maskRef),
										CGImageGetBitsPerComponent(maskRef),
										CGImageGetBitsPerPixel(maskRef),
										CGImageGetBytesPerRow(maskRef),
										CGImageGetDataProvider(maskRef),
										NULL,
										true);
    
	CGFloat scale = 1.5f;
	CGRect box = CGRectMake(self.touchPoint.x - self.mask.size.width / scale / 2,
							self.touchPoint.y - self.mask.size.height / scale / 2,
							self.mask.size.width / scale,
							self.mask.size.height / scale);
	
	CGImageRef subImage = CGImageCreateWithImageInRect(imageRef, box);
	
	CGImageRef xMaskedImage = CGImageCreateWithMask(subImage, mask);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGAffineTransform xform = CGAffineTransformMake(1.0,  0.0,
													0.0, -1.0,
													0.0,  0.0);
	CGContextConcatCTM(context, xform);
	
	CGRect area = CGRectMake(0, 0, self.mask.size.width, - self.mask.size.height);
	
	CGContextDrawImage(context, area, xMaskedImage);
	CGContextDrawImage(context, area, overlay);
}

@end
#endif
