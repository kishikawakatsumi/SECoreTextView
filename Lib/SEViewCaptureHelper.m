//
//  SEViewCaptureHelper.m
//  SECoreTextView-iOS
//
//  Created by ryohey on 2015/03/16.
//  Copyright (c) 2015年 kishikawa katsumi. All rights reserved.
//

#import "SEViewCaptureHelper.h"

#if TARGET_OS_IPHONE

@implementation SEViewCaptureHelper

+ (UIImage *)captureView:(UIView *)view
                  center:(CGPoint)center
                    size:(CGSize)size
                   scale:(CGFloat)scale {
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    
    CGFloat x = ceilf(center.x - size.width / scale / 2);
    CGFloat y = ceilf(center.y - size.height / scale / 2);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, scale, scale);
    CGContextTranslateCTM(context, -x, -y);
    
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *captureImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return captureImage;
}

@end
#endif
