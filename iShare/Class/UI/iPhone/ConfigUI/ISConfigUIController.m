//
//  ISConfigUIViewController.m
//  iShare
//
//  Created by Jin Jin on 12-9-11.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISConfigUIController.h"

@interface ISConfigUIController ()

@end

@implementation ISConfigUIController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = NSLocalizedString(@"tab_title_config", nil);
        self.tabBarItem.title = NSLocalizedString(@"tab_title_config", nil);
        self.tabBarItem.image = [UIImage imageNamed:@"ic_tab_config"];
    }
    return self;
}

- (void)viewDidLoad

{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_texture"]];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor clearColor];
    
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(NSString*)settingFilename{
    return @"ISSettingConfig";
}

@end
