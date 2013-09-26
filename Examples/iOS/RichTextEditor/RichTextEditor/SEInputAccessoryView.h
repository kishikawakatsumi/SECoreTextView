//
//  SEInputAccessoryView.h
//  RichTextEditor
//
//  Created by kishikawa katsumi on 13/09/26.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SEInputAccessoryView : UIToolbar

@property (nonatomic, weak) IBOutlet UIBarButtonItem *keyboardButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *stampButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *photoButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *smallerButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *largerButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *colorButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *boldButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *italicButton;

@end
