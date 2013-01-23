//
//  JJMoviePlayerViewController.h.m
//  iShare
//
//  Created by Jin Jin on 12-12-21.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "JJMoviePlayerViewController.h"

typedef enum {
    JJMovieViewContentAspectFit,
    JJMovieViewContentAspectFill
} JJMovieViewContentStyle;

@interface JJMoviePlayerViewController ()

@property (nonatomic, copy) NSString* filepath;
@property (nonatomic, strong) JJMoviePlayerController* moviePlayerController;

@property (nonatomic, assign) JJMovieViewContentStyle contentStyle;

@property (nonatomic, weak) NSTimer* timer;

@end

@implementation JJMoviePlayerViewController

-(id)initWithFilepath:(NSString*)filepath{
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    
    if (self){
        self.filepath = filepath;
        self.moviePlayerController = [[JJMoviePlayerController alloc] initWithFilepath:self.filepath];
        self.moviePlayerController.delegate = self;
        self.wantsFullScreenLayout = YES;
        self.contentStyle = JJMovieViewContentAspectFit;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //add gesture recognizer
    UITapGestureRecognizer* doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapDetected:)];
    doubleTap.numberOfTapsRequired = 2;
    UITapGestureRecognizer* singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapDetected:)];
    singleTap.numberOfTapsRequired = 1;
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [self.view addGestureRecognizer:doubleTap];
    [self.view addGestureRecognizer:singleTap];
    //add movie display view as subview
    [self.view addSubview:self.moviePlayerController.view];
    self.moviePlayerController.view.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    //create and add navigation bar
    [self.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [self.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsLandscapePhone];
    [self.view addSubview:self.navigationBar];
    //add control panel
    [self.view addSubview:self.controlerPanel];
    //create and add control button
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonClicked:)];
    [doneButton setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    UINavigationItem* navigationItem = [[UINavigationItem alloc] init];
    navigationItem.titleView = self.playStatusView;
    navigationItem.leftBarButtonItem = doneButton;
    
    self.navigationBar.items = @[navigationItem];
    
    [self.playControlBtn setImage:[UIImage imageNamed:@"PlayControl_play"] forState:UIControlStateNormal];
    [self.playControlBtn addTarget:self action:@selector(pausePlayBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    UIImage* progressLeft = [[UIImage imageNamed:@"Progress_Left"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    UIImage* progressRight = [[UIImage imageNamed:@"Progress_Right"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    [self.volumeBar setMinimumTrackImage:progressLeft
                                forState:UIControlStateNormal];
    [self.volumeBar setMaximumTrackImage:progressRight
                                forState:UIControlStateNormal];
    [self.playProgress setMinimumTrackImage:progressLeft
                                   forState:UIControlStateNormal];
    [self.playProgress setMaximumTrackImage:progressRight
                                   forState:UIControlStateNormal];
    
    [self.volumeBar setThumbImage:[UIImage imageNamed:@"VolumeProgress_Knob"]
                         forState:UIControlStateNormal];
    [self.volumeBar setThumbImage:[UIImage imageNamed:@"VolumeProgress_Knob"]
                         forState:UIControlStateHighlighted];
    [self.playProgress setThumbImage:[UIImage imageNamed:@"PlayProgress_Knob"]
                            forState:UIControlStateNormal];
    [self.playProgress setThumbImage:[UIImage imageNamed:@"PlayProgress_Knob"]
                            forState:UIControlStateHighlighted];
    
    [self.volumeBar addTarget:self action:@selector(volumeBarValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.volumeBar addTarget:self action:@selector(volumeBarValueChangeEnded:) forControlEvents:UIControlEventTouchUpInside];
    self.volumeBar.value = [self.moviePlayerController currentVolume];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent
                                                animated:YES];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.timer invalidate];
    self.timer = nil;
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
    CGFloat controlPanelWidth = 316;
    CGFloat controlPanelHeight = 80;
    frame = CGRectMake((width - controlPanelWidth)/2, self.view.bounds.size.height-controlPanelHeight-2, controlPanelWidth, controlPanelHeight);
    self.controlerPanel.frame = frame;
    //layout control bar, make it in the bottom always
    //layout display view and make it fit to size
    [self updateDisplayViewWithStyle:self.contentStyle animated:NO];
}

-(UIView*)rotatingHeaderView{
    return self.navigationBar;
}

#pragma mark - timer
-(void)scheduleHiddenTimer{
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(hideToolbars:) userInfo:nil repeats:NO];
}

static CGFloat animation_duration = 0.4f;

-(void)hideToolbars:(NSTimer*)timer{
    [UIView animateWithDuration:animation_duration animations:^{
        self.navigationBar.alpha = 0.0f;
        self.controlerPanel.alpha = 0.0f;
    }completion:^(BOOL finished){
        self.navigationBar.hidden = YES;
        self.controlerPanel.hidden = YES;
    }];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES
                                            withAnimation:UIStatusBarAnimationFade];
}

-(void)showToolbars{
    [self.view setNeedsLayout];
    
    self.navigationBar.hidden = NO;
    self.controlerPanel.hidden = NO;
    [UIView animateWithDuration:animation_duration animations:^{
        self.navigationBar.alpha = 1.0f;
        self.controlerPanel.alpha = 1.0f;
    }completion:^(BOOL finished){
    }];

    [[UIApplication sharedApplication] setStatusBarHidden:NO
                                            withAnimation:UIStatusBarAnimationFade];
}

#pragma mark - button action
-(void)doneButtonClicked:(id)sender{
    [self.moviePlayerController stop];
    [self dismissViewControllerAnimated:YES
                             completion:NULL];
}

-(void)pausePlayBtnClicked:(id)sender{
    if (self.moviePlayerController.status == JJMoviePlaybackStatusPlay){
        [self.moviePlayerController pause];
    }else{
        [self.moviePlayerController play];
    }
}

-(void)pauseButtonClicked:(id)sender{
    [self.moviePlayerController pause];
}

#pragma mark - gesture action
-(void)doubleTapDetected:(UITapGestureRecognizer*)gesture{
    //change view size
    if (self.contentStyle == JJMovieViewContentAspectFill){
        self.contentStyle = JJMovieViewContentAspectFit;
    }else if (self.contentStyle == JJMovieViewContentAspectFit){
        self.contentStyle = JJMovieViewContentAspectFill;
    }

    [self updateDisplayViewWithStyle:self.contentStyle animated:YES];
}

-(void)singleTapDetected:(UITapGestureRecognizer*)gesture{
    [self showToolbars];
    [self scheduleHiddenTimer];
}

#pragma mark - movie player delegate
-(void)moviePlayerWillStart:(JJMoviePlayerController *)player{
    [self.view setNeedsLayout];
}

-(void)moviePlayerDidStart:(JJMoviePlayerController *)player{
    [self.playControlBtn setImage:[UIImage imageNamed:@"PlayControl_pause"]
                         forState:UIControlStateNormal];

    [self scheduleHiddenTimer];
}

-(void)moviePlayerDidPause:(JJMoviePlayerController *)player{
    [self.playControlBtn setImage:[UIImage imageNamed:@"PlayControl_play"]
                         forState:UIControlStateNormal];
}

#pragma mark - view operation
-(void)updateDisplayViewWithStyle:(JJMovieViewContentStyle)style animated:(BOOL)animated{
    
    CGRect frame;
    CGFloat duration = (animated)?0.2f:0;
    
    if (style == JJMovieViewContentAspectFit){
        CGSize natrualSize = self.moviePlayerController.natrualSize;
        
        CGFloat ration = [self scaleRationWithContentSize:natrualSize
                                            containerSize:self.view.bounds.size
                                                    style:style];
        
        CGSize size = CGSizeApplyAffineTransform(natrualSize, CGAffineTransformMakeScale(ration, ration));
        CGFloat x = CGRectGetMidX(self.view.bounds) - size.width/2;
        CGFloat y = CGRectGetMidY(self.view.bounds) - size.height/2;
        
        frame = CGRectMake(x, y, size.width, size.height);
        
    }else if (style == JJMovieViewContentAspectFill){
        CGFloat height, width;
        if (UIDeviceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)){
            height = [UIScreen mainScreen].bounds.size.height;
            width = [UIScreen mainScreen].bounds.size.width;
        }else{
            width = [UIScreen mainScreen].bounds.size.height;
            height = [UIScreen mainScreen].bounds.size.width;
        }
        
        frame = CGRectMake(0, 0, width, height);
    }
    
    [UIView animateWithDuration:duration animations:^{
        self.moviePlayerController.view.frame = frame;
    }];
}

-(CGFloat)scaleRationWithContentSize:(CGSize)contentSize
                       containerSize:(CGSize)containerSize
                               style:(JJMovieViewContentStyle)style{
    CGFloat widthRation = containerSize.width/contentSize.width;
    CGFloat heightRation = containerSize.height/contentSize.height;
    
    CGFloat ration;
    if (style == JJMovieViewContentAspectFit){
        ration = MIN(widthRation, heightRation);
    }else{
        ration = MAX(widthRation, heightRation);
    }
    
    return ration;
}

#pragma mark - slider bar control
-(void)volumeBarValueChanged:(id)sender{
    //stop timer
    [self.timer invalidate];
    self.timer = nil;
    float value = self.volumeBar.value;
    //set volume
    [self.moviePlayerController setVolume:value];
}

-(void)volumeBarValueChangeEnded:(id)sender{
    [self scheduleHiddenTimer];
}

@end
