//
//  TextEditorViewController.m
//  iShare
//
//  Created by Jin Jin on 12-11-26.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "TextEditorViewController.h"

@interface TextEditorViewController (){
    BOOL _keyboardShows;
}

@property (nonatomic, strong) NSString* filePath;
@property (nonatomic, strong) UIDocumentInteractionController* documentInteractionController;

@end

@implementation TextEditorViewController

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(id)initWithFilePath:(NSString *)filePath{
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    
    if (self){
        self.filePath = filePath;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];

    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.rightBarButtonItem = self.openInButton;
    NSString* fileContent = [NSString stringWithContentsOfFile:self.filePath encoding:NSUTF8StringEncoding error:NULL];
    self.textView.text = fileContent;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self saveFile];
}

-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    if (!_keyboardShows){
        self.textView.frame = self.view.bounds;
    }
}

-(IBAction)openInButtonClicked:(id)sender{
    self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:self.filePath]];
    self.documentInteractionController.delegate = self;
    UIViewController* rootController = [UIApplication sharedApplication].keyWindow.rootViewController;
    BOOL result = [self.documentInteractionController presentOpenInMenuFromRect:rootController.view.bounds inView:rootController.view animated:YES];
    
    if (result == NO){
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"alert_message_nosuitableapp", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
    }
}

-(void)saveFile{
    [self.textView.text writeToFile:self.filePath
                         atomically:YES
                           encoding:NSUTF8StringEncoding
                              error:NULL];
}

#pragma mark - keyboard change 
- (void)keyboardWillShow:(NSNotification *)notification {
    
    /*
     Reduce the size of the text view so that it's not obscured by the keyboard.
     Animate the resize so that it's in sync with the appearance of the keyboard.
     */
    
    NSDictionary *userInfo = [notification userInfo];
    
    // Get the origin of the keyboard when it's displayed.
    NSValue* aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    
    // Get the top of the keyboard as the y coordinate of its origin in self's view's coordinate system. The bottom of the text view's frame should align with the top of the keyboard's final position.
    CGRect keyboardRect = [aValue CGRectValue];
    
    // Get the duration of the animation.
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration ;
    [animationDurationValue getValue:&animationDuration];
    
    CGRect frame = self.view.frame;
    frame.size.height -= keyboardRect.size.height - 45;
    
    [UIView animateWithDuration:animationDuration animations:^{
        self.textView.frame = frame;
    }];
    
    _keyboardShows = YES;
}


- (void)keyboardWillHide:(NSNotification *)notification {
    
    NSDictionary* userInfo = [notification userInfo];
    
    /*
     Restore the size of the text view (fill self's view).
     Animate the resize so that it's in sync with the disappearance of the keyboard.
     */
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView animateWithDuration:animationDuration animations:^{
        self.textView.frame = self.view.frame;
    }];
    
    _keyboardShows = NO;
}

@end
