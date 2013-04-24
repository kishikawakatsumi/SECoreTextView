//
//  SECompatibility.m
//  SECoreTextView
//
//  Created by kishikawa katsumi on 2013/04/21.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import "SECompatibility.h"

#if TARGET_OS_IPHONE
NSString * const NSLinkAttributeName = @"NSLink";

@implementation UIColor (Compatibility)

+ (UIColor *)selectedTextBackgroundColor
{
    return [UIColor colorWithRed:0.654656 green:0.792518 blue:0.999198 alpha:1.0];
}

+ (UIColor *)selectedMenuItemColor
{
    return [UIColor colorWithRed:0.286 green:0.549 blue:0.859 alpha:1.000];
}

@end
#else
@implementation NSColor (Compatibility)

- (CGColorRef)createCGColor
{
    const NSInteger numberOfComponents = [self numberOfComponents];
    CGFloat components[numberOfComponents];
    CGColorSpaceRef colorSpace = [[self colorSpace] CGColorSpace];
	
    [self getComponents:(CGFloat *)&components];
	
    return CGColorCreate(colorSpace, components);
}

@end
#endif
