//
//  SELinkGeometry.m
//  SECoreTextView
//
//  Created by kishikawa katsumi on 2013/04/20.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import "SELinkGeometry.h"
#import "SECompatibility.h"

@implementation SELinkGeometry

- (id)init
{
    return [self initWithRect:CGRectZero lineNumber:NSNotFound];
}

- (id)initWithRect:(CGRect)rect lineNumber:(NSInteger)lineNumber
{
    self = [super init];
    if (self) {
        _rect = rect;
        _lineNumber = lineNumber;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Line: %@, Range: %@", @(self.lineNumber), NSStringFromRect(self.rect)];
}

@end
