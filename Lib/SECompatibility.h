//
//  SECompatibility.h
//  SECoreTextView
//
//  Created by kishikawa katsumi on 2013/04/21.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>

@compatibility_alias NSView UIView;
@compatibility_alias NSFont UIFont;
@compatibility_alias NSColor UIColor;
@compatibility_alias NSBezierPath UIBezierPath;
@compatibility_alias NSImage UIImage;

typedef UIEdgeInsets NSEdgeInsets;

#define NSEdgeInsetsMake UIEdgeInsetsMake
#define NSRectFill UIRectFill
#define NSStringFromRect NSStringFromCGRect

extern NSString * const NSLinkAttributeName;

#else
#import <Cocoa/Cocoa.h>

@compatibility_alias UIView NSView;
@compatibility_alias UIFont NSFont;
@compatibility_alias UIColor NSColor;
@compatibility_alias UIBezierPath NSBezierPath;
@compatibility_alias UIImage NSImage;

typedef NSEdgeInsets UIEdgeInsets;

#define UIEdgeInsetsMake NSEdgeInsetsMake
#define UIRectFill NSRectFill
#define NSStringFromCGRect NSStringFromRect

@interface NSColor (Compatibility)

- (CGColorRef)createCGColor;

@end

#endif
