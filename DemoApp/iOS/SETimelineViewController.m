//
//  SETimelineViewController.m
//  SECoreTextView-iOS
//
//  Created by kishikawa katsumi on 2013/04/21.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import "SETimelineViewController.h"
#import "SETweetViewController.h"
#import "SEWebViewController.h"
#import "SETimelineCell.h"
#import "SETextView.h"
#import "SELinkText.h"
#import "SEImageCache.h"
#import "SETwitterHelper.h"

static const CGFloat LINE_SPACING = 4.0f;
static const CGFloat FONT_SIZE = 14.0f;

@interface SETimelineViewController () <UITableViewDataSource, UITableViewDelegate, SETextViewDelegate>

@property (strong, nonatomic) NSArray *timeline;
@property (strong, nonatomic) NSURL *nextURL;

@end

@implementation SETimelineViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    ACAccountStore *accountStore = [[ACAccountStore alloc]init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [accountStore requestAccessToAccountsWithType:accountType withCompletionHandler:^(BOOL granted, NSError *error)
     {
         if (granted) {
             NSArray *accounts = [accountStore accountsWithAccountType:accountType];
             
             if (accounts.count > 0) {
                 ACAccount *account = accounts[0];
                 [self getHomeTimlineWithAccount:account];
             }
         }
     }];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.timeline.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *tweet = self.timeline[indexPath.row];
    NSAttributedString *attributedString = [[SETwitterHelper sharedInstance] attributedStringWithTweet:tweet];
    CGRect frameRect = [SETextView frameRectWithAttributtedString:attributedString
                                                   constraintSize:CGSizeMake(tableView.bounds.size.width - 72.0f, CGFLOAT_MAX)
                                                      lineSpacing:LINE_SPACING
                                                             font:[UIFont systemFontOfSize:FONT_SIZE]];
    
    return MAX(tableView.rowHeight, frameRect.size.height + 26.0f);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    SETimelineCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    NSDictionary *tweet = self.timeline[indexPath.row];
    
    NSURL *iconURL = [NSURL URLWithString:tweet[@"user"][@"profile_image_url_https"]];
    UIImage *iconImage = [[SEImageCache sharedInstance] imageForURL:iconURL
                                                       defaultImage:[NSImage imageNamed:@"default_user_icon"]
                                                    completionBlock:^(NSImage *image, NSError *error)
                          {
                              if (image && [cell.profileIconURL isEqual:iconURL]) {
                                  cell.iconImageView.image = image;
                              }
                          }];
    cell.iconImageView.image = iconImage;
    cell.profileIconURL = iconURL;
    
    NSDictionary *user = tweet[@"user"];
    cell.screenNameLabel.text = user[@"name"];
    cell.nameLabel.text = [NSString stringWithFormat:@"@%@", user[@"screen_name"]];
    
    cell.tweetTextView.attributedText = [[SETwitterHelper sharedInstance] attributedStringWithTweet:tweet];
    cell.tweetTextView.lineSpacing = LINE_SPACING;
    cell.tweetTextView.font = [UIFont systemFontOfSize:FONT_SIZE];
    cell.tweetTextView.delegate = self;
    
    return cell;
}

#pragma mark -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"TweetView"]) {
        NSDictionary *tweet = self.timeline[self.tableView.indexPathForSelectedRow.row];
        
        SETweetViewController *controler = segue.destinationViewController;
        controler.tweet = tweet;
    } else if ([segue.identifier isEqualToString:@"WebView"]) {
        SEWebViewController *controler = segue.destinationViewController;
        controler.URL = self.nextURL;
        
        self.nextURL = nil;
    }
}

#pragma mark -

- (BOOL)textView:(SETextView *)aTextView clickedOnLink:(SELinkText *)link atIndex:(NSUInteger)charIndex
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

#pragma mark -

- (void)getHomeTimlineWithAccount:(ACAccount *)account
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSURL *requestURL = [NSURL URLWithString:@"https://api.twitter.com/1/statuses/home_timeline.json"];
    NSDictionary *params = @{@"count": @"200", @"include_entities": @"true"};
    id request = nil;
    
    Class clazz = NSClassFromString(@"SLRequest");
    if (clazz) {
        request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                     requestMethod:SLRequestMethodGET
                                               URL:requestURL
                                        parameters:params];
        ((SLRequest *)request).account = account;
    } else {
        request = [[TWRequest alloc] initWithURL:requestURL
                                      parameters:params
                                   requestMethod:TWRequestMethodGET];
        ((TWRequest *)request).account = account;
    }
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
     {
         [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
         
         if (error) {
             [self showAlertOnError:error];
             return;
         }
         
         NSError *parseError = nil;
         id result = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&parseError];
         
         if (parseError) {
             [self showAlertOnError:parseError];
             return;
         }
         
         if ([result isKindOfClass:[NSDictionary class]]) {
             NSArray *errors = result[@"errors"];
             if (errors) {
                 NSInteger code = [((NSDictionary *)errors.lastObject)[@"code"] integerValue];
                 NSString *message = ((NSDictionary *)errors.lastObject)[@"message"];
                 
                 NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: message}];
                 [self showAlertOnError:error];
                 return;
             }
         }
         
         if ([result isKindOfClass:[NSArray class]]) {
             self.timeline = result;
             dispatch_async(dispatch_get_main_queue(), ^
                            {
                                [self.tableView reloadData];
                            });
             return;
         }
         
         [self showAlertOnError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:@{NSLocalizedDescriptionKey: @"Unknown error occurred."}]];
     }];
}

#pragma mark -

- (void)showAlertOnError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"SECoreTextView"
                                                                           message:error.localizedDescription
                                                                          delegate:self
                                                                 cancelButtonTitle:nil
                                                                 otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                       [alertView show];
                   });
}

@end
