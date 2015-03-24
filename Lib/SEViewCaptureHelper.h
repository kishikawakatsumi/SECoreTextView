//
//  SEViewCaptureHelper.h
//  SECoreTextView-iOS
//
//  Created by ryohey on 2015/03/16.
//  Copyright (c) 2015年 kishikawa katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

@interface SEViewCaptureHelper : NSObject

/// Capturing UIView to UIImage around center
+ (UIImage *)captureView:(UIView *)view
                  center:(CGPoint)center
                    size:(CGSize)size
                   scale:(CGFloat)scale;

@end
#endif
