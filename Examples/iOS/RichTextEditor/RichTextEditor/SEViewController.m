//
//  SEViewController.m
//  RichTextEditor
//
//  Created by kishikawa katsumi on 13/09/26.
//  Copyright (c) 2013 kishikawa katsumi. All rights reserved.
//

#import "SEViewController.h"
#import "SEInputAccessoryView.h"
#import "SEStampInputView.h"
#import "SEPhotoView.h"
#import "SETextView.h"

static const CGFloat defaultFontSize = 18.0f;

@interface SEViewController () <SETextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet SETextView *textView;
@property (nonatomic) SEInputAccessoryView *inputAccessoryView;
@property (nonatomic) SEStampInputView *imageInputView;

@end

@implementation SEViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.imageInputView = [[[UINib nibWithNibName:@"SEStampInputView" bundle:nil] instantiateWithOwner:nil options:nil] lastObject];
    [self.imageInputView.button1 addTarget:self action:@selector(stamp:) forControlEvents:UIControlEventTouchUpInside];
    [self.imageInputView.button2 addTarget:self action:@selector(stamp:) forControlEvents:UIControlEventTouchUpInside];
    [self.imageInputView.button3 addTarget:self action:@selector(stamp:) forControlEvents:UIControlEventTouchUpInside];
    [self.imageInputView.button4 addTarget:self action:@selector(stamp:) forControlEvents:UIControlEventTouchUpInside];
    [self.imageInputView.button5 addTarget:self action:@selector(stamp:) forControlEvents:UIControlEventTouchUpInside];
    [self.imageInputView.button6 addTarget:self action:@selector(stamp:) forControlEvents:UIControlEventTouchUpInside];
    [self.imageInputView.button7 addTarget:self action:@selector(stamp:) forControlEvents:UIControlEventTouchUpInside];
    [self.imageInputView.button8 addTarget:self action:@selector(stamp:) forControlEvents:UIControlEventTouchUpInside];
    [self.imageInputView.button9 addTarget:self action:@selector(stamp:) forControlEvents:UIControlEventTouchUpInside];
    [self.imageInputView.button10 addTarget:self action:@selector(stamp:) forControlEvents:UIControlEventTouchUpInside];
    [self.imageInputView.button11 addTarget:self action:@selector(stamp:) forControlEvents:UIControlEventTouchUpInside];
    [self.imageInputView.button12 addTarget:self action:@selector(stamp:) forControlEvents:UIControlEventTouchUpInside];
    [self.imageInputView.button13 addTarget:self action:@selector(stamp:) forControlEvents:UIControlEventTouchUpInside];
    [self.imageInputView.button14 addTarget:self action:@selector(stamp:) forControlEvents:UIControlEventTouchUpInside];
    [self.imageInputView.button15 addTarget:self action:@selector(stamp:) forControlEvents:UIControlEventTouchUpInside];
    
    self.inputAccessoryView = [[[UINib nibWithNibName:@"SEInputAccessoryView" bundle:nil] instantiateWithOwner:nil options:nil] lastObject];
    self.inputAccessoryView.keyboardButton.target = self;
    self.inputAccessoryView.keyboardButton.action = @selector(showKeyboard:);
    self.inputAccessoryView.stampButton.target = self;
    self.inputAccessoryView.stampButton.action = @selector(showStampInputView:);
    self.inputAccessoryView.photoButton.target = self;
    self.inputAccessoryView.photoButton.action = @selector(showImagePicker:);
    self.inputAccessoryView.boldButton.target = self;
    self.inputAccessoryView.boldButton.action = @selector(bold:);
    self.inputAccessoryView.italicButton.target = self;
    self.inputAccessoryView.italicButton.action = @selector(italic:);
    
    self.textView.inputAccessoryView = self.inputAccessoryView;
    self.textView.editable = YES;
    self.textView.lineSpacing = 8.0f;
    self.textView.font = [UIFont systemFontOfSize:defaultFontSize];
    self.textView.text = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"InitialText" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
}

- (void)viewWillLayoutSubviews
{
    [self updateLayout];
}

#pragma mark -

- (void)textViewDidChangeSelection:(SETextView *)textView
{
    NSRange selectedRange = textView.selectedRange;
    if (selectedRange.location != NSNotFound && selectedRange.length > 0) {
        self.inputAccessoryView.boldButton.enabled = YES;
        self.inputAccessoryView.italicButton.enabled = YES;
    } else {
        self.inputAccessoryView.boldButton.enabled = NO;
        self.inputAccessoryView.italicButton.enabled = NO;
    }
}

- (void)textViewDidChange:(SETextView *)textView
{
    [self updateLayout];
}

- (void)updateLayout
{
    CGSize containerSize = self.scrollView.bounds.size;
    CGSize contentSize = [self.textView sizeThatFits:containerSize];
    
    CGRect frame = self.textView.frame;
    frame.size.height = MAX(contentSize.height, containerSize.height);
    
    self.textView.frame = frame;
    self.scrollView.contentSize = frame.size;
    
    [self.scrollView scrollRectToVisible:self.textView.caretRect animated:YES];
}

#pragma mark -

- (IBAction)showKeyboard:(id)sender
{
    self.textView.inputView = nil;
    [self.textView reloadInputViews];
    
    self.inputAccessoryView.keyboardButton.enabled = NO;
    self.inputAccessoryView.stampButton.enabled = YES;
}

- (IBAction)showStampInputView:(id)sender
{
    self.textView.inputView = self.imageInputView;
    [self.textView reloadInputViews];
    
    self.inputAccessoryView.keyboardButton.enabled = YES;
    self.inputAccessoryView.stampButton.enabled = NO;
}

- (IBAction)showImagePicker:(id)sender
{
    [self.textView resignFirstResponder];
    
    UIImagePickerController *controller = [[UIImagePickerController alloc] init];
    controller.delegate = self;
    controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:controller animated:YES completion:NULL];
}

- (IBAction)bold:(id)sender
{
    NSRange selectedRange = self.textView.selectedRange;
    if (selectedRange.location != NSNotFound && selectedRange.length > 0) {
        self.textView.font = nil;
        
        NSMutableAttributedString *attributedString = self.textView.attributedText.mutableCopy;
        [attributedString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:defaultFontSize] range:selectedRange];
        self.textView.attributedText = attributedString;
    }
}

- (IBAction)italic:(id)sender
{
    NSRange selectedRange = self.textView.selectedRange;
    if (selectedRange.location != NSNotFound && selectedRange.length > 0) {
        self.textView.font = nil;
        
        NSMutableAttributedString *attributedString = self.textView.attributedText.mutableCopy;
        [attributedString addAttribute:NSFontAttributeName value:[UIFont italicSystemFontOfSize:defaultFontSize] range:selectedRange];
        self.textView.attributedText = attributedString;
    }
}

- (IBAction)stamp:(id)sender
{
    UIButton *button = sender;
    UIImage *stampImage = [button imageForState:UIControlStateNormal];
    if (stampImage) {
        [self.textView insertObject:stampImage size:stampImage.size];
    }
}

#pragma mark -

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    
    SEPhotoView *photoView = [[SEPhotoView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 80.0f)];
    photoView.image = image;
    
    [self.textView insertObject:photoView size:photoView.bounds.size];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
