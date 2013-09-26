//
//  SETwitterHelper.h
//  SECoreTextView-Mac
//
//  Created by kishikawa katsumi on 2013/04/21.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import "TwitterText.h"

@interface SETwitterHelper : NSObject

+ (SETwitterHelper *)sharedInstance;
- (NSAttributedString *)attributedStringWithTweet:(NSDictionary *)tweet;

@end
