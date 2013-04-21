//
//  SELinkText.h
//  SECoreTextView
//
//  Created by kishikawa katsumi on 2013/04/20.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SELinkGeometry;

@interface SELinkText : NSObject

@property (strong, nonatomic, readonly) NSString *text;
@property (strong, nonatomic, readonly) id object;
@property (assign, nonatomic, readonly) NSRange range;
@property (strong, nonatomic, readonly) NSArray *geometries;

- (id)initWithText:(NSString *)text object:(id)object range:(NSRange)range;
- (void)addLinkGeometry:(SELinkGeometry *)geometry;

@end
