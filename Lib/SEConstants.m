//
//  SEConstants.m
//  SECoreTextView-iOS
//
//  Created by kishikawa katsumi on 2013/04/27.
//  Copyright (c) 2013年 kishikawa katsumi. All rights reserved.
//

#import "SEConstants.h"

@implementation SEConstants

+ (NSColor *)selectedTextBackgroundColor
{
#if TARGET_OS_IPHONE
    return [UIColor colorWithRed:0.654656 green:0.792518 blue:0.999198 alpha:1.0];
#else
    return [NSColor selectedTextBackgroundColor];
#endif
}

+ (NSColor *)linkColor
{
#if TARGET_OS_IPHONE
    return [UIColor colorWithRed:0.286 green:0.549 blue:0.859 alpha:1.000];
#else
    return [NSColor colorWithCalibratedRed:0.286 green:0.549 blue:0.859 alpha:1.000];
#endif
}

+ (NSColor *)selectionGrabberColor
{
#if TARGET_OS_IPHONE
    return [UIColor colorWithRed:0.259 green:0.420 blue:0.949 alpha:1.000];
#else
    return [NSColor colorWithCalibratedRed:0.259 green:0.420 blue:0.949 alpha:1.000];
#endif
}

@end
