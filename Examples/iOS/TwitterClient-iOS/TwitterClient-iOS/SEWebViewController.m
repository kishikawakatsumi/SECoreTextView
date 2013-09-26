//
//  SEWebViewController.m
//  SECoreTextView-iOS
//
//  Created by kishikawa katsumi on 2013/04/21.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import "SEWebViewController.h"

@interface SEWebViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation SEWebViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.URL]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

@end
