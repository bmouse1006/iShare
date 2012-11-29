//
//  ISGoogleAuth2ViewController.m
//  iShare
//
//  Created by Jin Jin on 12-11-28.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISGoogleAuth2ViewController.h"

@interface ISGoogleAuth2ViewController ()

@end

@implementation ISGoogleAuth2ViewController

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
    UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelClicked:)];
    self.navigationItem.rightBarButtonItem = cancelButton;
	// Do any additional setup after loading the view.
}

-(void)cancelClicked:(id)sender{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
