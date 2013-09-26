//
//  SEAppDelegate.h
//  SECoreTextView
//
//  Created by kishikawa katsumi on 2013/04/21.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>

@interface SEAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTableView *tableView;

@end
