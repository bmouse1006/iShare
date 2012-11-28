//
//  TextEditorViewController.m
//  iShare
//
//  Created by Jin Jin on 12-11-26.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "TextEditorViewController.h"

@interface TextEditorViewController ()

@property (nonatomic, strong) NSString* filePath;
@property (nonatomic, strong) UIDocumentInteractionController* documentInteractionController;

@end

@implementation TextEditorViewController

-(id)initWithFilePath:(NSString *)filePath{
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    
    if (self){
        self.filePath = filePath;
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
    self.textView.frame = self.view.bounds;
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

#pragma mark - document interaction delegate



@end
