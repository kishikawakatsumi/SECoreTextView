//
//  SELinkGeometry.h
//  SECoreTextView
//
//  Created by kishikawa katsumi on 2013/04/20.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SELinkGeometry : NSObject

@property (assign, nonatomic, readonly) CGRect rect;
@property (assign, nonatomic, readonly) NSInteger lineNumber;

- (id)initWithRect:(CGRect)rect lineNumber:(NSInteger)lineNumber;

@end
