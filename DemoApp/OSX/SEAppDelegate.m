//
//  SEAppDelegate.m
//  SECoreTextView
//
//  Created by kishikawa katsumi on 2013/04/21.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import "SEAppDelegate.h"
#import "SETweetCellView.h"
#import "SELinkText.h"
#import "SEImageCache.h"
#import "SETwitterHelper.h"

static const CGFloat LINE_SPACING = 4.0f;

@interface SEAppDelegate () <NSTableViewDataSource, NSTableViewDelegate, SETextViewDelegate>

@property (strong, nonatomic) NSArray *timeline;
@property (assign, nonatomic) CGFloat tableColumnWidth;

@end

@implementation SEAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    ACAccountStore *accountStore = [[ACAccountStore alloc]init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error)
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

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return NO;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
    [[self window] makeKeyAndOrderFront:nil];
    return YES;
}

- (void)getHomeTimlineWithAccount:(ACAccount *)account
{
    NSURL *requestURL = [NSURL URLWithString:@"https://api.twitter.com/1/statuses/user_timeline.json"];
    NSDictionary *params = @{@"count": @"200", @"include_entities": @"true", @"screen_name": @"k_katsumi"};
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodGET
                                                      URL:requestURL
                                               parameters:params];
    request.account = account;
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
     {
         
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
                       NSAlert *alert = [NSAlert alertWithMessageText:error.localizedDescription
                                                        defaultButton:NSLocalizedString(@"OK", nil)
                                                      alternateButton:nil
                                                          otherButton:nil
                                            informativeTextWithFormat:@""];
                       [alert beginSheetModalForWindow:self.window
                                         modalDelegate:self
                                        didEndSelector:nil
                                           contextInfo:nil];
                   });
}

#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    NSTableColumn *column = tableView.tableColumns[0];
    self.tableColumnWidth = column.width;
    
    return self.timeline.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSDictionary *tweet = self.timeline[row];
    
    SETweetCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    NSURL *iconURL = [NSURL URLWithString:tweet[@"user"][@"profile_image_url_https"]];
    NSImage *iconImage = [[SEImageCache sharedInstance] imageForURL:iconURL
                                                        defaultImage:[NSImage imageNamed:@"default_user_icon"]
                                                     completionBlock:^(NSImage *image, NSError *error)
                          {
                              if (image) {
                                  cellView.iconImageView.image = image;
                              }
                          }];
    cellView.iconImageView.image = iconImage;
    
    NSDictionary *user = tweet[@"user"];
    cellView.screenNameTextField.stringValue = user[@"name"];
    cellView.nameTextField.stringValue = [NSString stringWithFormat:@"@%@", user[@"screen_name"]];
    
    cellView.tweetTextView.attributedText = [[SETwitterHelper sharedInstance] attributedStringWithTweet:tweet];
    cellView.tweetTextView.lineSpacing = LINE_SPACING;
    cellView.tweetTextView.delegate = self;
    [cellView.tweetTextView clearSelection];
    
    return cellView;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    NSDictionary *tweet = self.timeline[row];
    NSAttributedString *attributedString = [[SETwitterHelper sharedInstance] attributedStringWithTweet:tweet];
    CGRect frameRect = [SETextView frameRectWithAttributtedString:attributedString
                                                   constraintSize:CGSizeMake(self.tableColumnWidth - 72.0f, CGFLOAT_MAX)
                                                      edgePadding:NSEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)
                                                      lineSpacing:LINE_SPACING];
    
    return MAX(tableView.rowHeight, frameRect.size.height + 26.0f);
}

#pragma mark -

- (void)tableViewColumnDidResize:(NSNotification *)notification {
    NSTableColumn *column = self.tableView.tableColumns[0];
    self.tableColumnWidth = column.width;
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0];
    [self.tableView noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.tableView.numberOfRows)]];
    [NSAnimationContext endGrouping];
}

#pragma mark -

- (BOOL)textView:(SETextView *)aTextView clickedOnLink:(SELinkText *)link atIndex:(NSUInteger)charIndex
{
    NSString *text = link.object;
    if ([text hasPrefix:@"http"]) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:text]];
    } else if ([text hasPrefix:@"@"]) {
        NSURL *userURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://twitter.com/%@", [text substringFromIndex:1]]];
        [[NSWorkspace sharedWorkspace] openURL:userURL];
    } else if ([text hasPrefix:@"#"]) {
        NSURL *searchURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://twitter.com/search?q=%%23%@", [text substringFromIndex:1]]];
        [[NSWorkspace sharedWorkspace] openURL:searchURL];
    }
    
    return YES;
}

@end
