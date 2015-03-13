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

@property (nonatomic, weak) IBOutlet UIBarButtonItem *doneButton;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet SETextView *textView;
@property (nonatomic) SEInputAccessoryView *inputAccessoryView;
@property (nonatomic) SEStampInputView *imageInputView;

@property (nonatomic) id normalFont;
@property (nonatomic) id boldFont;

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
    self.inputAccessoryView.nomalButton.target = self;
    self.inputAccessoryView.nomalButton.action = @selector(nomal:);
    self.inputAccessoryView.boldButton.target = self;
    self.inputAccessoryView.boldButton.action = @selector(bold:);
    
    self.textView.inputAccessoryView = self.inputAccessoryView;
    self.textView.editable = YES;
    self.textView.lineSpacing = 8.0f;
    NSString *initialText = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"InitialText" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:initialText];
    
    UIColor *linkColor = [UIColor blueColor];
    
    UIFont *normalFont = [UIFont systemFontOfSize:defaultFontSize];
    CTFontRef ctNormalFont = CTFontCreateWithName((__bridge CFStringRef)normalFont.fontName, normalFont.pointSize, NULL);
    self.normalFont = (__bridge id)ctNormalFont;
    CFRelease(ctNormalFont);
    
    UIFont *boldFont = [UIFont boldSystemFontOfSize:defaultFontSize];
    CTFontRef ctBoldFont = CTFontCreateWithName((__bridge CFStringRef)boldFont.fontName, boldFont.pointSize, NULL);
    self.boldFont = (__bridge id)ctBoldFont;
    CFRelease(ctBoldFont);
    
    [attributedString addAttribute:(id)kCTFontAttributeName value:self.normalFont range:NSMakeRange(0, initialText.length)];
    
    NSRange firstRange = NSMakeRange(2, 7);
    [attributedString addAttribute:(id)kCTFontAttributeName value:self.boldFont range:firstRange];
    [attributedString addAttribute:(id)kCTUnderlineStyleAttributeName value:@YES range:firstRange];
    [attributedString addAttribute:NSLinkAttributeName value:[NSURL URLWithString:@"http://ja.wikipedia.org/wiki/%E3%82%A4%E3%83%BC%E3%83%8F%E3%83%88%E3%83%BC%E3%83%96"] range:firstRange];
    [attributedString addAttribute:(id)kCTForegroundColorAttributeName value:(id)linkColor.CGColor range:firstRange];
    
    NSRange secondRange = NSMakeRange(45, 5);
    [attributedString addAttribute:(id)kCTFontAttributeName value:self.normalFont range:secondRange];
    [attributedString addAttribute:(id)kCTForegroundColorAttributeName value:(id)[[UIColor redColor] CGColor] range:secondRange];
    
    self.textView.attributedText = attributedString;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillLayoutSubviews
{
    [self updateLayout];
}

- (IBAction)done:(id)sender
{
    [self.textView resignFirstResponder];
}

#pragma mark -

- (void)textViewDidBeginEditing:(SETextView *)textView
{
    self.doneButton.enabled = YES;
}

- (void)textViewDidEndEditing:(SETextView *)textView
{
    self.doneButton.enabled = NO;
}

- (void)textViewDidChangeSelection:(SETextView *)textView
{
    NSRange selectedRange = textView.selectedRange;
    if (selectedRange.location != NSNotFound && selectedRange.length > 0) {
        self.inputAccessoryView.boldButton.enabled = YES;
        self.inputAccessoryView.nomalButton.enabled = YES;
    } else {
        self.inputAccessoryView.boldButton.enabled = NO;
        self.inputAccessoryView.nomalButton.enabled = NO;
    }
}

- (void)textViewDidChange:(SETextView *)textView
{
    [self updateLayout];
}

#pragma mark -

- (void)keyboardWillShow:(NSNotification *)notification
{
    self.scrollView.scrollEnabled = NO;
    
    CGRect keyboardBounds;
    [notification.userInfo[UIKeyboardFrameEndUserInfoKey] getValue:&keyboardBounds];
    
    keyboardBounds = [self.view convertRect:keyboardBounds toView:nil];
    
    CGRect containerFrame = self.scrollView.frame;
    containerFrame.size.height = CGRectGetHeight(self.view.bounds) - CGRectGetHeight(keyboardBounds);
    
    self.scrollView.frame = containerFrame;
    
    self.scrollView.scrollEnabled = YES;
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    self.scrollView.scrollEnabled = NO;
    
    CGRect keyboardBounds;
    [notification.userInfo[UIKeyboardFrameEndUserInfoKey] getValue:&keyboardBounds];
    
    keyboardBounds = [self.view convertRect:keyboardBounds toView:nil];
    
    CGRect containerFrame = self.scrollView.frame;
    containerFrame.size.height = CGRectGetHeight(self.view.bounds) - CGRectGetHeight(keyboardBounds);
    
    self.scrollView.frame = containerFrame;
    
    self.scrollView.scrollEnabled = YES;
}

- (void)updateLayout
{
    CGSize containerSize = self.scrollView.frame.size;
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

- (IBAction)nomal:(id)sender
{
    NSRange selectedRange = self.textView.selectedRange;
    if (selectedRange.location != NSNotFound && selectedRange.length > 0) {
        self.textView.font = nil;
        
        NSMutableAttributedString *attributedString = self.textView.attributedText.mutableCopy;
        [attributedString addAttribute:(id)kCTFontAttributeName value:self.normalFont range:selectedRange];
        self.textView.attributedText = attributedString;
    }
}

- (IBAction)bold:(id)sender
{
    NSRange selectedRange = self.textView.selectedRange;
    if (selectedRange.location != NSNotFound && selectedRange.length > 0) {
        self.textView.font = nil;
        
        NSMutableAttributedString *attributedString = self.textView.attributedText.mutableCopy;
        [attributedString addAttribute:(id)kCTFontAttributeName value:self.boldFont range:selectedRange];
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
