//
//  MainTabBarController.m
//  iShare
//
//  Created by Jin Jin on 12-8-3.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "MainTabBarController.h"
#import "ISFileBrowserController.h"
#import "ISMusicPlayerController.h"
#import "ISFileShareController.h"
#import "ISConfigUIController.h"

@interface MainTabBarController ()

@end

@implementation MainTabBarController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self loadAllControllers];
        [self customizeUI];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

-(BOOL)shouldAutorotate{
    return NO;
}

-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)loadAllControllers{
    ISFileBrowserController* fileBrowser = [[ISFileBrowserController alloc] initWithFilePath:nil];
    ISMusicPlayerController* musicPlayer = [[ISMusicPlayerController alloc] init];
    ISFileShareController* fileShare = [[ISFileShareController alloc] init];
    ISConfigUIController* configUI = [[ISConfigUIController alloc] init];
    
    NSArray* controllers = @[fileBrowser, musicPlayer, fileShare, configUI];
    
    NSMutableArray* navController = [NSMutableArray array];
    
    [controllers enumerateObjectsUsingBlock:^(UIViewController* viewController, NSUInteger idx, BOOL* stop){
        if ([viewController isKindOfClass:[UINavigationController class]] == NO){
            [navController addObject:[[UINavigationController alloc] initWithRootViewController:viewController]];
        }else{
            [navController addObject:viewController];
        }
    }];
    
    [self setViewControllers:navController];
}

-(void)customizeUI{
    self.tabBar.backgroundImage = [UIImage imageNamed:@"bg_tab_bar"];
//    self.tabBar.selectedImageTintColor = [UIColor greenColor];
}

@end
