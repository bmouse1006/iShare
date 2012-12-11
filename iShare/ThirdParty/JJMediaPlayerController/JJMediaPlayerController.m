//
//  JJMediaPlayerController.m
//  iShare
//
//  Created by Jin Jin on 12-12-5.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "SDL.h"
#import "SDL_audio.h"
#import "SDL_video.h"

#import "JJMediaPlayerController.h"
#import "FFMPEGMovieExtractor.h"
#import "AudioPlay.h"
#import <MediaPlayer/MediaPlayer.h>

@interface JJMediaPlayerController (){
    NSTimeInterval lastFrameTime;
}

@property (nonatomic, strong) MPVolumeView* volumeView;
@property (nonatomic, strong) UIImageView* displayView;
@property (nonatomic, strong) AudioPlay* audioPlay;
@property (nonatomic, strong) FFMPEGMovieExtractor* movieExtractor;

@property (nonatomic, strong) UIImage* previousNavImage;
@property (nonatomic, assign) UIBarStyle previousBarStyle;
@property (nonatomic, assign) UIStatusBarStyle previousStatusBarStyle;

@property (nonatomic, weak) NSTimer* timer;

@end

@implementation JJMediaPlayerController

/**
 init of JJMediaPlayerController with file path
 @param filePath
 @return id
 @exception nil
 */
-(id)initWithFilepath:(NSString*)filePath{
    self = [super init];
    if (self){
        self.movieExtractor = [[FFMPEGMovieExtractor alloc] initWithVideo:filePath];
        self.audioPlay = [[AudioPlay alloc] init];
        self.hidesBottomBarWhenPushed = YES;
    }
    
    return self;
}

/**
 init of JJMediaPlayerController with input stream
 @param input stream
 @return id
 @exception nil
 */
-(id)initWithInputStream:(NSInputStream*)inputStream{
    self = [super init];
    if (self){
        
    }
    
    return self;
}

-(void)loadView{
    //create a container view
    self.view = [[UIView alloc] initWithFrame:CGRectZero];
    //create image view to display video
    self.displayView = [[UIImageView alloc] initWithFrame:CGRectZero];
    //create volumeView
    self.volumeView = [[MPVolumeView alloc] initWithFrame:CGRectZero];
    //add to super view
    [self.view addSubview:self.displayView];
    [self.view addSubview:self.volumeView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //hide bottom tab bar
    //set background color
    self.view.backgroundColor = [UIColor blackColor];
    self.volumeView.showsRouteButton = YES;
    self.volumeView.showsVolumeSlider = YES;
	
    [self setupFFMPEGSource];
//    if ([self setupSDLWithFFMPEGMovieExtractor:self.movieExtractor]){
        //SDL init failed
        //don't play
//    }
    [self.audioPlay openAL];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self playVideo];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //set nav bar as black opaque
    self.previousNavImage = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault];
    self.previousBarStyle = self.navigationController.navigationBar.barStyle;
    [self.navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    //save and set status bar style
    self.previousStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    //restore navigation bar status
    self.navigationController.navigationBar.barStyle = self.previousBarStyle;
    [self.navigationController.navigationBar setBackgroundImage:self.previousNavImage forBarMetrics:UIBarMetricsDefault];
    //restore status bar style
    [UIApplication sharedApplication].statusBarStyle = self.previousStatusBarStyle;
    
    [self.timer invalidate];
}

-(void)viewWillLayoutSubviews{
    //layout subviews here
    //layout display image view
    self.displayView.frame = CGRectMake(0, 0, 200, 200);
    self.displayView.backgroundColor = [UIColor redColor];
    //TODO
    //layout volumn view
    self.volumeView.frame = CGRectMake(200, 200, 100, 50);
    self.volumeView.backgroundColor = [UIColor whiteColor];
    //TODO
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setupFFMPEGSource{
    //start load video here
    // set output image size
	self.movieExtractor.outputWidth = 426;
	self.movieExtractor.outputHeight = 320;
	
	// print some info about the video
	NSLog(@"video duration: %f",self.movieExtractor.duration);
	NSLog(@"video size: %d x %d", self.movieExtractor.sourceWidth, self.movieExtractor.sourceHeight);
}

-(BOOL)setupSDLWithFFMPEGMovieExtractor:(FFMPEGMovieExtractor*)extractor{
    return YES;
    if (SDL_Init(SDL_INIT_AUDIO | SDL_INIT_VIDEO) < 0) {
        //error
        DebugLog(@"SDL init failed");
        return YES;
    }
    
    return NO;
}

-(void)playVideo{
    lastFrameTime = -1;
	
	// seek to 0.0 seconds
	[self.movieExtractor seekTime:0.0];
    
	self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0/60
                                                  target:self
                                                selector:@selector(playNextFrame:)
                                                userInfo:nil
                                                 repeats:YES];
}

#define LERP(A,B,C) ((A)*(1.0-C)+(B)*C)

-(void)playNextFrame:(NSTimer *)timer {
	NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
	if (![self.movieExtractor stepFrame]) {
		[timer invalidate];
		return;
	}
    
	self.displayView.image = self.movieExtractor.currentImage;
//    NSData* audioData = self.movieExtractor.currentSound;
    [self.audioPlay enqueueAudioPacket:self.movieExtractor.pAudioFrame];
	float frameTime = 1.0/([NSDate timeIntervalSinceReferenceDate]-startTime);
	if (lastFrameTime<0) {
		lastFrameTime = frameTime;
	} else {
		lastFrameTime = LERP(frameTime, lastFrameTime, 0.8);
	}
}


@end
