//
//  SETweetCellView.h
//  SECoreTextView
//
//  Created by kishikawa katsumi on 2013/04/21.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SETextView.h"

@interface SETweetCellView : NSTableCellView

@property (weak, nonatomic) IBOutlet NSImageView *iconImageView;
@property (weak, nonatomic) IBOutlet NSTextField *screenNameTextField;
@property (weak, nonatomic) IBOutlet NSTextField *nameTextField;
@property (weak, nonatomic) IBOutlet SETextView *tweetTextView;

@end
