//
//  SETwitterHelper.m
//  SECoreTextView-Mac
//
//  Created by kishikawa katsumi on 2013/04/21.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import "SETwitterHelper.h"
#import "SECompatibility.h"

@implementation SETwitterHelper {
    NSCache *_attributedStringCache;
}

+ (SETwitterHelper *)sharedInstance
{
    static SETwitterHelper *sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SETwitterHelper alloc] init];
    });
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _attributedStringCache = [[NSCache alloc] init];
    }
    return self;
}

- (NSAttributedString *)attributedStringWithTweet:(NSDictionary *)tweet
{
    NSString *text = tweet[@"text"];
    if (!text) {
        return [[NSAttributedString alloc] init];
    }
    if ([_attributedStringCache objectForKey:text]) {
        return [_attributedStringCache objectForKey:text];
    }
    
    UIFont *font = [UIFont systemFontOfSize:13.0f];
    CTFontRef tweetfont = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, NULL);
    
    NSColor *tweetColor = [NSColor blackColor];
    NSColor *hashtagColor = [NSColor grayColor];
    UIColor *cashtagColor = [UIColor grayColor];
    NSColor *linkColor = [NSColor blueColor];
    
    NSDictionary *attributes = @{(id)kCTForegroundColorAttributeName: (id)tweetColor.CGColor, (id)kCTFontAttributeName: (__bridge id)tweetfont};
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
    CFRelease(tweetfont);
    
    NSDictionary *entities = tweet[@"entities"];
    NSArray *userMentions = entities[@"user_mentions"];
    for (NSDictionary *userMention in userMentions) {
        NSArray *indices = userMention[@"indices"];
        NSInteger first = [indices.firstObject integerValue];
        NSInteger last = [indices.lastObject integerValue];
        NSRange range = NSMakeRange(first, last - first);
        [attributedString addAttributes:@{NSLinkAttributeName: [text substringWithRange:range], (id)kCTForegroundColorAttributeName: (id)linkColor.CGColor}
                                  range:range];
    }
    NSArray *hashtags = entities[@"hashtags"];
    for (NSDictionary *hashtag in hashtags) {
        NSArray *indices = hashtag[@"indices"];
        NSInteger first = [indices.firstObject integerValue];
        NSInteger last = [indices.lastObject integerValue];
        NSRange range = NSMakeRange(first, last - first);
        [attributedString addAttributes:@{NSLinkAttributeName: [text substringWithRange:range], (id)kCTForegroundColorAttributeName: (id)hashtagColor.CGColor}
                                  range:range];
    }
    NSArray *symbols = entities[@"symbols"];
    for (NSDictionary *symbol in symbols) {
        NSArray *indices = symbol[@"indices"];
        NSInteger first = [indices.firstObject integerValue];
        NSInteger last = [indices.lastObject integerValue];
        NSRange range = NSMakeRange(first, last - first);
        [attributedString addAttributes:@{NSLinkAttributeName: [text substringWithRange:range], (id)kCTForegroundColorAttributeName: (id)cashtagColor.CGColor}
                                  range:range];
    }
    
    NSArray *urls = entities[@"urls"];
    NSArray *media = entities[@"media"];
    urls = [urls arrayByAddingObjectsFromArray:media];
    for (NSDictionary *url in urls.reverseObjectEnumerator) {
        NSArray *indices = url[@"indices"];
        
        NSInteger first = [indices[0] integerValue];
        NSInteger last = [indices[1] integerValue];
        for (NSInteger i = 0; i < first; i++) {
            unichar c = [text characterAtIndex:i];
            if (CFStringIsSurrogateHighCharacter(c)) {
                first++;
                last++;
            }
        }
        for (NSInteger i = first; i < last; i++) {
            unichar c = [text characterAtIndex:i];
            if (CFStringIsSurrogateHighCharacter(c)) {
                last++;
            }
        }
        
        NSString *replace = url[@"display_url"];
        
        [attributedString replaceCharactersInRange:NSMakeRange(first, last - first) withString:replace];
        [attributedString addAttributes:@{NSLinkAttributeName: url[@"expanded_url"], (id)kCTForegroundColorAttributeName: (id)linkColor.CGColor}
                                  range:NSMakeRange(first, replace.length)];
    }
    
    NSDictionary *refs = @{@"&amp;": @"&", @"&lt;": @"<", @"&gt;": @">", @"&quot;": @"\"", @"&apos;": @"'"};
    for (NSString *key in refs.allKeys.reverseObjectEnumerator) {
        NSRange range = [attributedString.string rangeOfString:key];
        while (range.location != NSNotFound) {
            [attributedString replaceCharactersInRange:range withString:refs[key]];
            range = [attributedString.string rangeOfString:key];
        }
    }
    
    [_attributedStringCache setObject:attributedString forKey:text];
    
    return attributedString;
}

@end
