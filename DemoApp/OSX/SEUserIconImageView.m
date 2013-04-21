//
//  SEUserIconImageView.m
//  SECoreTextView
//
//  Created by kishikawa katsumi on 2013/04/21.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import "SEUserIconImageView.h"

@implementation SEUserIconImageView

- (void)drawRect:(NSRect)dirtyRect
{
    NSBezierPath *bezierPath = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:4.0f yRadius:4.0f];
    [bezierPath addClip];
    
    [super drawRect:dirtyRect];
}

@end
