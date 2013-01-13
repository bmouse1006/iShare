//
//  JJMoviePlayerViewController.h.m
//  iShare
//
//  Created by Jin Jin on 12-12-21.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "JJMoviePlayerViewController.h"
#import "JJMoviePlayerController.h"

@interface JJMoviePlayerViewController ()

@property (nonatomic, copy) NSString* filepath;
@property (nonatomic, strong) JJMoviePlayerController* moviePlayerController;
@property (nonatomic, strong) UIView* controlerPanel;

@property (nonatomic, strong) UINavigationBar* navigationBar;

@end

@implementation JJMoviePlayerViewController

-(id)initWithFilepath:(NSString*)filepath{
    self = [super init];
    
    if (self){
        self.filepath = filepath;
        self.moviePlayerController = [[JJMoviePlayerController alloc] initWithFilepath:self.filepath];
        self.wantsFullScreenLayout = YES;
    }
    
    return self;
}

-(void)loadView{
    //create container view
    UIView* view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    view.backgroundColor = [UIColor redColor];
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //add movie display view as subview
    [self.view addSubview:self.moviePlayerController.view];
    self.moviePlayerController.view.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    //add control panel
    [self.view addSubview:self.controlerPanel];
    //create and add navigation bar
    self.navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectZero];
    [self.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [self.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsLandscapePhone];
    self.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    self.navigationBar.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.navigationBar];
    //create and add control button
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneButtonClicked:)];
    UIBarButtonItem* playButton = [[UIBarButtonItem alloc] initWithTitle:@"Play" style:UIBarButtonItemStylePlain target:self action:@selector(playButtonClickedd:)];
    
    UINavigationItem* navigationItem = [[UINavigationItem alloc] initWithTitle:@"title"];
    navigationItem.rightBarButtonItem = doneButton;
    navigationItem.leftBarButtonItem = playButton;
    self.navigationBar.items = @[navigationItem];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent
                                                animated:YES];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault
                                                animated:YES];
}

-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    CGFloat width = self.view.frame.size.width;
    CGFloat height = self.view.frame.size.height;
    CGFloat barHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    UIInterfaceOrientation orientation = [[UIDevice currentDevice] orientation];
    if (UIInterfaceOrientationIsLandscape(orientation)){
        //exchange width and height
        CGFloat temp = width;
        width = height;
        height = temp;
        barHeight = [UIApplication sharedApplication].statusBarFrame.size.width;
    }
    //layout navigation bar, makes it on the top always
    CGRect frame = CGRectMake(0, barHeight, width, 44);
    self.navigationBar.frame = frame;
    //layout control bar, make it in the bottom always
    //layout display view and make it fit to size
    
}

-(UIView*)rotatingHeaderView{
    return self.navigationBar;
}

#pragma mark - button action
-(void)doneButtonClicked:(id)sender{
    [self dismissViewControllerAnimated:YES
                             completion:NULL];
}

-(void)playButtonClickedd:(id)sender{
    [self.moviePlayerController play];
}

-(void)stopButtonClicked:(id)sender{
    
}

-(void)pauseButtonClicked:(id)sender{
    
}

@end
