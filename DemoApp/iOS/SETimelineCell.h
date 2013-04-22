//
//  SETimelineCell.h
//  SECoreTextView-iOS
//
//  Created by kishikawa katsumi on 2013/04/21.
//  Copyright (c) 2013年 kishikawa katsumi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "SETextView.h"

@interface SETimelineCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *screenNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet SETextView *tweetTextView;
@property (strong, nonatomic) NSURL *profileIconURL;

@end
