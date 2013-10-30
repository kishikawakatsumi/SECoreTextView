//
//  SETweetViewController.m
//  SECoreTextView-iOS
//
//  Created by kishikawa katsumi on 2013/04/21.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import "SETweetViewController.h"
#import "SEWebViewController.h"
#import "SETextView.h"
#import "SELinkText.h"
#import "SEImageCache.h"
#import "SETwitterHelper.h"

static const CGFloat LINE_SPACING = 4.0f;
static const CGFloat FONT_SIZE = 16.0f;

@interface SETweetViewController () <UITableViewDataSource, UITableViewDelegate, SETextViewDelegate>

@property (weak, nonatomic) IBOutlet UITableViewCell *userCell;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *screenNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet SETextView *tweetTextView;

@property (strong, nonatomic) NSURL *nextURL;

@end

@implementation SETweetViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.userCell.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.iconImageView.layer.cornerRadius = 4.0f;
    self.iconImageView.layer.masksToBounds = YES;
    
    NSURL *iconURL = [NSURL URLWithString:self.tweet[@"user"][@"profile_image_url_https"]];
    UIImage *iconImage = [[SEImageCache sharedInstance] imageForURL:iconURL
                                                       defaultImage:[NSImage imageNamed:@"default_user_icon"]
                                                    completionBlock:^(NSImage *image, NSError *error)
                          {
                              if (image) {
                                  self.iconImageView.image = image;
                              }
                          }];
    self.iconImageView.image = iconImage;
    
    NSDictionary *user = self.tweet[@"user"];
    self.screenNameLabel.text = user[@"name"];
    self.nameLabel.text = [NSString stringWithFormat:@"@%@", user[@"screen_name"]];
    
    NSMutableAttributedString *attributedText = [[[SETwitterHelper sharedInstance] attributedStringWithTweet:self.tweet] mutableCopy];
    
    UIFont *font = [UIFont systemFontOfSize:FONT_SIZE];
    CTFontRef tweetfont = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, NULL);
    [attributedText addAttributes:@{(id)kCTFontAttributeName: (__bridge id)tweetfont} range:NSMakeRange(0, attributedText.length)];
    CFRelease(tweetfont);
    
    self.tweetTextView.attributedText = attributedText;
    self.tweetTextView.lineSpacing = LINE_SPACING;
    self.tweetTextView.selectable = YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

#pragma mark -

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return tableView.rowHeight;
    } else {
        CGRect frameRect = [SETextView frameRectWithAttributtedString:self.tweetTextView.attributedText
                                                       constraintSize:CGSizeMake(284.0f, CGFLOAT_MAX)
                                                          lineSpacing:self.tweetTextView.lineSpacing];
        
        return frameRect.size.height + 20.0f;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"WebView"]) {
        SEWebViewController *controler = segue.destinationViewController;
        controler.URL = self.nextURL;
        
        self.nextURL = nil;
    }
}

#pragma mark -

- (BOOL)textView:(SETextView *)textView clickedOnLink:(SELinkText *)link atIndex:(NSUInteger)charIndex
{
    NSString *text = link.object;
    if ([text hasPrefix:@"http"]) {
        self.nextURL = [NSURL URLWithString:text];
    } else if ([text hasPrefix:@"@"]) {
        self.nextURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://twitter.com/%@", [text substringFromIndex:1]]];
    } else if ([text hasPrefix:@"#"]) {
        self.nextURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://twitter.com/search?q=%%23%@", [text substringFromIndex:1]]];
    }
    
    if (self.nextURL) {
        [self performSegueWithIdentifier:@"WebView" sender:self];
    }
    
    return YES;
}

- (void)textViewDidChangeSelection:(SETextView *)aTextView
{
    
}

@end
