//
//  SETimelineCell.m
//  SECoreTextView-iOS
//
//  Created by kishikawa katsumi on 2013/04/21.
//  Copyright (c) 2013年 kishikawa katsumi. All rights reserved.
//

#import "SETimelineCell.h"

@implementation SETimelineCell

- (void)awakeFromNib
{
    self.iconImageView.layer.cornerRadius = 4.0f;
    self.iconImageView.layer.masksToBounds = YES;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.screenNameLabel sizeToFit];
    [self.nameLabel sizeToFit];
    
    CGRect screenNameLabelFrame = self.screenNameLabel.frame;
    CGRect nameLabelFrame = self.nameLabel.frame;
    nameLabelFrame.origin.x = CGRectGetMaxX(screenNameLabelFrame) + 8.0f;
    nameLabelFrame.size.width = MAX(CGRectGetMaxX(self.bounds) - CGRectGetMinX(nameLabelFrame) - 8.0f, 0.0f);
    self.nameLabel.frame = nameLabelFrame;
}

@end
