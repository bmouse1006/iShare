//
//  AudioPlayer.m
//  MobileTheatre
//
//  Created by Matt Donnelly on 27/03/2010.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "MDAudioPlayerController.h"
#import "MDAudioFile.h"
#import "MDAudioPlayerTableViewCell.h"

@interface MDAudioPlayerController (){
    BOOL _previousNavigationBarHidden;
}

@property (nonatomic, strong) UIImage* barButtonImage;

- (UIImage *)reflectedImage:(UIButton *)fromImage withHeight:(NSUInteger)height;

@end

@implementation MDAudioPlayerController

static const CGFloat kDefaultReflectionFraction = 0.65;
static const CGFloat kDefaultReflectionOpacity = 0.40;

@synthesize player;
@synthesize gradientLayer;

@synthesize playButton;
@synthesize pauseButton;
@synthesize nextButton;
@synthesize previousButton;
@synthesize toggleButton;
@synthesize repeatButton;
@synthesize shuffleButton;

@synthesize currentTime;
@synthesize duration;
@synthesize indexLabel;
@synthesize titleLabel;
@synthesize artistLabel;
@synthesize albumLabel;

@synthesize volumeSlider;
@synthesize progressSlider;

@synthesize songTableView;

@synthesize artworkView;
@synthesize reflectionView;
@synthesize containerView;
@synthesize overlayView;

@synthesize updateTimer;

@synthesize interrupted;
@synthesize repeatAll;
@synthesize repeatOne;
@synthesize shuffle;

void interruptionListenerCallback (void *userData, UInt32 interruptionState)
{
	MDAudioPlayerController *vc = (__bridge MDAudioPlayerController *)userData;
	if (interruptionState == kAudioSessionBeginInterruption)
		vc.interrupted = YES;
	else if (interruptionState == kAudioSessionEndInterruption)
		vc.interrupted = NO;
}

-(void)updateCurrentTime:(NSTimeInterval)curTime duration:(NSTimeInterval)durTime
{
    NSString *current = [NSString stringWithFormat:@"%d:%02d", (int)curTime / 60, (int)curTime % 60, nil];
    NSString *dur = [NSString stringWithFormat:@"-%d:%02d", (int)((int)(durTime - curTime)) / 60, (int)((int)(durTime - curTime)) % 60, nil];
    duration.text = dur;
    currentTime.text = current;
    progressSlider.value = curTime;
}

- (void)updateCurrentTime
{
    if (SliderValueIsChanging == NO){
        [self updateCurrentTime:self.player.currentTime duration:self.player.duration];
    }
}

- (void)updateViewForPlayerState:(AVAudioPlayer *)p
{
	titleLabel.text = [[self.playList objectAtIndex:selectedIndex] title];
	artistLabel.text = [[self.playList objectAtIndex:selectedIndex] artist];
	albumLabel.text = [[self.playList objectAtIndex:selectedIndex] album];
	
	[self updateCurrentTime:p.currentTime duration:p.duration];
	
	if (updateTimer) 
		[updateTimer invalidate];
	
	if (p.playing)
	{
		[playButton removeFromSuperview];
		[self.view addSubview:pauseButton];
		updateTimer = [NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(updateCurrentTime) userInfo:p repeats:YES];
	}
	else
	{
		[pauseButton removeFromSuperview];
		[self.view addSubview:playButton];
		updateTimer = nil;
	}
	
	if (![songTableView superview]) 
	{
		[artworkView setImage:[[self.playList objectAtIndex:selectedIndex] coverImage] forState:UIControlStateNormal];
		reflectionView.image = [self reflectedImage:artworkView withHeight:artworkView.bounds.size.height * kDefaultReflectionFraction];
	}
	
	if (repeatOne || repeatAll || shuffle)
		nextButton.enabled = YES;
	else	
		nextButton.enabled = [self canGoToNextTrack];
	previousButton.enabled = [self canGoToPreviousTrack];
}

-(void)updateViewForPlayerInfo:(AVAudioPlayer*)p
{
	duration.text = [NSString stringWithFormat:@"%d:%02d", (int)p.duration / 60, (int)p.duration % 60, nil];
	indexLabel.text = [NSString stringWithFormat:@"%d of %d", (selectedIndex + 1), [self.playList count]];
	progressSlider.maximumValue = p.duration;
	if ([[NSUserDefaults standardUserDefaults] floatForKey:@"PlayerVolume"])
		volumeSlider.value = [[NSUserDefaults standardUserDefaults] floatForKey:@"PlayerVolume"];
	else
		volumeSlider.value = p.volume;
}

-(void)dealloc{
    self.player.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(MDAudioPlayerController*)initWithAudioPlayerManager:(JJAudioPlayerManager*)playerManager{
    self = [super init];
    if (self){
        self.player = [playerManager currentPlayer];
        self.player.delegate = self;
        self.playList = [NSMutableArray arrayWithArray:playerManager.currentPlayList];
        selectedIndex = playerManager.currentIndex;
        
        [self updateViewForPlayerInfo:player];
		[self updateViewForPlayerState:player];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    
    return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.view.backgroundColor = [UIColor blackColor];
    self.hidesBottomBarWhenPushed = YES;
	
//	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
	
	updateTimer = nil;
	
	UINavigationBar *navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
	navigationBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	navigationBar.barStyle = UIBarStyleBlackOpaque;
    [navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
	[self.view addSubview:navigationBar];
	
	UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:@""];
	[navigationBar pushNavigationItem:navItem animated:NO];
	
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissAudioPlayer)];
	
	self.toggleButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
	[toggleButton setImage:[UIImage imageNamed:@"AudioPlayerAlbumInfo"] forState:UIControlStateNormal];
	[toggleButton addTarget:self action:@selector(showSongFiles) forControlEvents:UIControlEventTouchUpInside];
	
	UIBarButtonItem *songsListBarButton = [[UIBarButtonItem alloc] initWithCustomView:toggleButton];
	
	navItem.leftBarButtonItem = doneButton;
	doneButton = nil;
	
	navItem.rightBarButtonItem = songsListBarButton;
	songsListBarButton = nil;
	
	navItem = nil;
    
//	AudioSessionInitialize(NULL, NULL, interruptionListenerCallback, (__bridge void *)(self));
//	AudioSessionSetActive(true);
//	UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
//	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);	
	
	MDAudioFile *selectedSong = [self.playList objectAtIndex:selectedIndex];
	  
	self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 14, 195, 12)];
	titleLabel.text = [selectedSong title];
	titleLabel.font = [UIFont boldSystemFontOfSize:12];
	titleLabel.backgroundColor = [UIColor clearColor];
	titleLabel.textColor = [UIColor whiteColor];
	titleLabel.shadowColor = [UIColor blackColor];
	titleLabel.shadowOffset = CGSizeMake(0, -1);
	titleLabel.textAlignment = UITextAlignmentCenter;
	titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
	[self.view addSubview:titleLabel];
	
	self.artistLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 2, 195, 12)];
	artistLabel.text = [selectedSong artist];
	artistLabel.font = [UIFont boldSystemFontOfSize:12];
	artistLabel.backgroundColor = [UIColor clearColor];
	artistLabel.textColor = [UIColor lightGrayColor];
	artistLabel.shadowColor = [UIColor blackColor];
	artistLabel.shadowOffset = CGSizeMake(0, -1);
	artistLabel.textAlignment = UITextAlignmentCenter;
	artistLabel.lineBreakMode = UILineBreakModeTailTruncation;
	[self.view addSubview:artistLabel];
	
	self.albumLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 27, 195, 12)];
	albumLabel.text = [selectedSong album];
	albumLabel.backgroundColor = [UIColor clearColor];
	albumLabel.font = [UIFont boldSystemFontOfSize:12];
	albumLabel.textColor = [UIColor lightGrayColor];
	albumLabel.shadowColor = [UIColor blackColor];
	albumLabel.shadowOffset = CGSizeMake(0, -1);
	albumLabel.textAlignment = UITextAlignmentCenter;
	albumLabel.lineBreakMode = UILineBreakModeTailTruncation;
	[self.view addSubview:albumLabel];

	navigationBar = nil;
	
	duration.adjustsFontSizeToFitWidth = YES;
	currentTime.adjustsFontSizeToFitWidth = YES;
	progressSlider.minimumValue = 0.0;	
	
	self.containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 44, self.view.bounds.size.width, self.view.bounds.size.height - 44)];
	[self.view addSubview:containerView];
	
	self.artworkView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 320, 320)];
	[artworkView setImage:[selectedSong coverImage] forState:UIControlStateNormal];
	[artworkView addTarget:self action:@selector(showOverlayView) forControlEvents:UIControlEventTouchUpInside];
	artworkView.showsTouchWhenHighlighted = NO;
	artworkView.adjustsImageWhenHighlighted = NO;
	artworkView.backgroundColor = [UIColor clearColor];
	[containerView addSubview:artworkView];
    artworkView.center = CGPointMake(CGRectGetMidX(containerView.bounds), CGRectGetMidY(containerView.bounds) - 48);
	
	self.reflectionView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 320, 320, 96)];
    CGRect frame = self.reflectionView.frame;
    frame.origin.y = artworkView.frame.origin.y + artworkView.frame.size.height;
    self.reflectionView.frame = frame;
	reflectionView.image = [self reflectedImage:artworkView withHeight:artworkView.bounds.size.height * kDefaultReflectionFraction];
	reflectionView.alpha = kDefaultReflectionFraction;
	[self.containerView addSubview:reflectionView];
	
	self.songTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 368)];
	self.songTableView.delegate = self;
	self.songTableView.dataSource = self;
	self.songTableView.separatorColor = [UIColor colorWithRed:0.986 green:0.933 blue:0.994 alpha:0.10];
	self.songTableView.backgroundColor = [UIColor clearColor];
	self.songTableView.contentInset = UIEdgeInsetsMake(0, 0, 37, 0); 
	self.songTableView.showsVerticalScrollIndicator = NO;
	
	gradientLayer = [[CAGradientLayer alloc] init];
	gradientLayer.frame = CGRectMake(0.0, self.containerView.bounds.size.height - 96, self.containerView.bounds.size.width, 48);
	gradientLayer.colors = [NSArray arrayWithObjects:(id)[UIColor clearColor].CGColor, (id)[UIColor colorWithWhite:0.0 alpha:0.5].CGColor, (id)[UIColor blackColor].CGColor, (id)[UIColor blackColor].CGColor, nil];
	gradientLayer.zPosition = INT_MAX;
	
	/*! HACKY WAY OF REMOVING EXTRA SEPERATORS */
	
	UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 10)];
	v.backgroundColor = [UIColor clearColor];
	[self.songTableView setTableFooterView:v];
	v = nil;

	UIImageView *buttonBackground = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 96, self.view.bounds.size.width, 96)];
//	buttonBackground.image = [[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"AudioPlayerBarBackground" ofType:@"png"]] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    buttonBackground.image = [UIImage imageNamed:@"AudioPlayerBarBackground"];
	[self.view addSubview:buttonBackground];
		
//	self.playButton = [[UIButton alloc] initWithFrame:CGRectMake(144, 370, 40, 40)];
    CGFloat playControlButtonOriginY = buttonBackground.frame.origin.y + 5;
    self.playButton = [[UIButton alloc] initWithFrame:CGRectMake(144, playControlButtonOriginY, 40, 40)];
//	[playButton setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"AudioPlayerPlay" ofType:@"png"]] forState:UIControlStateNormal];
    [playButton setImage:[UIImage imageNamed:@"AudioPlayerPlay"] forState:UIControlStateNormal];
	[playButton addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];
	playButton.showsTouchWhenHighlighted = YES;
	[self.view addSubview:playButton];
							  
	self.pauseButton = [[UIButton alloc] initWithFrame:CGRectMake(140, playControlButtonOriginY, 40, 40)];
//	[pauseButton setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"AudioPlayerPause" ofType:@"png"]] forState:UIControlStateNormal];
	[pauseButton setImage:[UIImage imageNamed:@"AudioPlayerPause"] forState:UIControlStateNormal];
	[pauseButton addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];
	pauseButton.showsTouchWhenHighlighted = YES;
	
	self.nextButton = [[UIButton alloc] initWithFrame:CGRectMake(220, playControlButtonOriginY, 40, 40)];
//	[nextButton setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"AudioPlayerNextTrack" ofType:@"png"]]
//				forState:UIControlStateNormal];
    [nextButton setImage:[UIImage imageNamed:@"AudioPlayerNextTrack"]
				forState:UIControlStateNormal];
	[nextButton addTarget:self action:@selector(next) forControlEvents:UIControlEventTouchUpInside];
	nextButton.showsTouchWhenHighlighted = YES;
	nextButton.enabled = [self canGoToNextTrack];
	[self.view addSubview:nextButton];
	
	self.previousButton = [[UIButton alloc] initWithFrame:CGRectMake(60, playControlButtonOriginY, 40, 40)];
//	[previousButton setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"AudioPlayerPrevTrack" ofType:@"png"]] 
//				forState:UIControlStateNormal];
	[previousButton setImage:[UIImage imageNamed:@"AudioPlayerPrevTrack"]
                    forState:UIControlStateNormal];
	[previousButton addTarget:self action:@selector(previous) forControlEvents:UIControlEventTouchUpInside];
	previousButton.showsTouchWhenHighlighted = YES;
	previousButton.enabled = [self canGoToPreviousTrack];
	[self.view addSubview:previousButton];
	
	self.volumeSlider = [[UISlider alloc] initWithFrame:CGRectMake(25, self.view.bounds.size.height - 35, 270, 9)];
	[volumeSlider setThumbImage:[UIImage imageNamed:@"AudioPlayerVolumeKnob"]
														forState:UIControlStateNormal];
	[volumeSlider setMinimumTrackImage:[[UIImage imageNamed:@"AudioPlayerScrubberLeft"] stretchableImageWithLeftCapWidth:5 topCapHeight:3]
					   forState:UIControlStateNormal];
	[volumeSlider setMaximumTrackImage:[[UIImage imageNamed:@"AudioPlayerScrubberRight"] stretchableImageWithLeftCapWidth:5 topCapHeight:3]
							  forState:UIControlStateNormal];
	[volumeSlider addTarget:self action:@selector(volumeSliderMoved:) forControlEvents:UIControlEventValueChanged];
	
	if ([[NSUserDefaults standardUserDefaults] floatForKey:@"PlayerVolume"])
		volumeSlider.value = [[NSUserDefaults standardUserDefaults] floatForKey:@"PlayerVolume"];
	else
		volumeSlider.value = player.volume;
		
	[self.view addSubview:volumeSlider];
	
	[self updateViewForPlayerInfo:player];
	[self updateViewForPlayerState:player];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    _previousNavigationBarHidden = self.navigationController.navigationBarHidden;
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    [self storeNaviagtionBarStatus];
}

-(void)storeNaviagtionBarStatus{
    self.barButtonImage = [[UIBarButtonItem appearance] backgroundImageForState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    [[UIBarButtonItem appearance] setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
}

-(void)restoreNavigationBarStatus{
    [[UIBarButtonItem appearance] setBackgroundImage:self.barButtonImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self playMusic];
	
	[self updateViewForPlayerInfo:player];
	[self updateViewForPlayerState:player];
}

- (void)dismissAudioPlayer
{
//    [self stopMusic];
    [self.navigationController popToRootViewControllerAnimated:YES];
	[self.parentViewController dismissModalViewControllerAnimated:YES];
}

- (void)showSongFiles
{
    static CGFloat animationDuration = 0.5f;
    
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:animationDuration];
	
	[UIView setAnimationTransition:([self.songTableView superview] ?
									UIViewAnimationTransitionFlipFromLeft : UIViewAnimationTransitionFlipFromRight)
						   forView:self.toggleButton cache:YES];
	if ([songTableView superview])
		[self.toggleButton setImage:[UIImage imageNamed:@"AudioPlayerAlbumInfo"] forState:UIControlStateNormal];
	else
		[self.toggleButton setImage:self.artworkView.imageView.image forState:UIControlStateNormal];
	
	[UIView commitAnimations];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:animationDuration];
	
	[UIView setAnimationTransition:([self.songTableView superview] ?
									UIViewAnimationTransitionFlipFromLeft : UIViewAnimationTransitionFlipFromRight)
						   forView:self.containerView cache:YES];
	if ([songTableView superview])
	{
		[self.songTableView removeFromSuperview];
		[self.artworkView setImage:[[self.playList objectAtIndex:selectedIndex] coverImage] forState:UIControlStateNormal];
		[self.containerView addSubview:reflectionView];
		
		[gradientLayer removeFromSuperlayer];
	}
	else
	{
		[self.artworkView setImage:[[UIImage imageNamed:@"AudioPlayerTableBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)] forState:UIControlStateNormal];
		[self.reflectionView removeFromSuperview];
		[self.overlayView removeFromSuperview];
		[self.containerView addSubview:songTableView];
		
		[[self.containerView layer] insertSublayer:gradientLayer atIndex:0];
	}
	
	[UIView commitAnimations];
}

- (void)showOverlayView
{	
	if (overlayView == nil) 
	{		
		self.overlayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 76)];
		overlayView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
		overlayView.opaque = NO;
		
		self.progressSlider = [[UISlider alloc] initWithFrame:CGRectMake(54, 20, 212, 23)];
		[progressSlider setThumbImage:[UIImage imageNamed:@"AudioPlayerScrubberKnob"]
						   forState:UIControlStateNormal];
		[progressSlider setMinimumTrackImage:[[UIImage imageNamed:@"AudioPlayerScrubberLeft"] stretchableImageWithLeftCapWidth:5 topCapHeight:3]
								  forState:UIControlStateNormal];
		[progressSlider setMaximumTrackImage:[[UIImage imageNamed:@"AudioPlayerScrubberRight"] stretchableImageWithLeftCapWidth:5 topCapHeight:3]
								  forState:UIControlStateNormal];
		[progressSlider addTarget:self action:@selector(progressSliderMoved:) forControlEvents:UIControlEventValueChanged];
        [progressSlider addTarget:self action:@selector(startChangeSliderValue:) forControlEvents:UIControlEventTouchDown];
        [progressSlider addTarget:self action:@selector(endChangeSliderValue:) forControlEvents:UIControlEventTouchUpInside];
        [progressSlider addTarget:self action:@selector(cancelChangeSliderValue:) forControlEvents:UIControlEventTouchUpOutside];
		progressSlider.maximumValue = player.duration;
		progressSlider.minimumValue = 0.0;	
		[overlayView addSubview:progressSlider];
		
		self.indexLabel = [[UILabel alloc] initWithFrame:CGRectMake(128, 2, 64, 21)];
		indexLabel.font = [UIFont boldSystemFontOfSize:12];
		indexLabel.shadowOffset = CGSizeMake(0, -1);
		indexLabel.shadowColor = [UIColor blackColor];
		indexLabel.backgroundColor = [UIColor clearColor];
		indexLabel.textColor = [UIColor whiteColor];
		indexLabel.textAlignment = UITextAlignmentCenter;
		[overlayView addSubview:indexLabel];
		
		self.duration = [[UILabel alloc] initWithFrame:CGRectMake(272, 21, 48, 21)];
		duration.font = [UIFont boldSystemFontOfSize:14];
		duration.shadowOffset = CGSizeMake(0, -1);
		duration.shadowColor = [UIColor blackColor];
		duration.backgroundColor = [UIColor clearColor];
		duration.textColor = [UIColor whiteColor];
		[overlayView addSubview:duration];
		
		self.currentTime = [[UILabel alloc] initWithFrame:CGRectMake(0, 21, 48, 21)];
		currentTime.font = [UIFont boldSystemFontOfSize:14];
		currentTime.shadowOffset = CGSizeMake(0, -1);
		currentTime.shadowColor = [UIColor blackColor];
		currentTime.backgroundColor = [UIColor clearColor];
		currentTime.textColor = [UIColor whiteColor];
		currentTime.textAlignment = UITextAlignmentRight;
		[overlayView addSubview:currentTime];
		
		duration.adjustsFontSizeToFitWidth = YES;
		currentTime.adjustsFontSizeToFitWidth = YES;
		
		self.repeatButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 45, 32, 28)];
		[repeatButton setImage:[UIImage imageNamed:@"AudioPlayerRepeatOff"]
					  forState:UIControlStateNormal];
		[repeatButton addTarget:self action:@selector(toggleRepeat) forControlEvents:UIControlEventTouchUpInside];
		[overlayView addSubview:repeatButton];
		
		self.shuffleButton = [[UIButton alloc] initWithFrame:CGRectMake(280, 45, 32, 28)];
		[shuffleButton setImage:[UIImage imageNamed:@"AudioPlayerShuffleOff"]
					  forState:UIControlStateNormal];
		[shuffleButton addTarget:self action:@selector(toggleShuffle) forControlEvents:UIControlEventTouchUpInside];
		[overlayView addSubview:shuffleButton];
	}
	
	[self updateViewForPlayerInfo:player];
	[self updateViewForPlayerState:player];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.4];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	
	if ([overlayView superview])
		[overlayView removeFromSuperview];
	else
		[containerView addSubview:overlayView];
	
	[UIView commitAnimations];
}

- (void)toggleShuffle
{
	if (shuffle)
	{
		shuffle = NO;
		[shuffleButton setImage:[UIImage imageNamed:@"AudioPlayerShuffleOff"] forState:UIControlStateNormal];
	}
	else
	{
		shuffle = YES;
		[shuffleButton setImage:[UIImage imageNamed:@"AudioPlayerShuffleOn"] forState:UIControlStateNormal];
	}
    
    [JJAudioPlayerManager sharedManager].playerMode ^= JJAudioPlayerModeShuffle;
	
	[self updateViewForPlayerInfo:player];
	[self updateViewForPlayerState:player];
}

- (void)toggleRepeat
{
	if (repeatOne)
	{
		[repeatButton setImage:[UIImage imageNamed:@"AudioPlayerRepeatOff"]
					  forState:UIControlStateNormal];
		repeatOne = NO;
		repeatAll = NO;
        [JJAudioPlayerManager sharedManager].playerMode  = JJAudioPlayerModeSequence;
	}
	else if (repeatAll)
	{
		[repeatButton setImage:[UIImage imageNamed:@"AudioPlayerRepeatOneOn"]
					  forState:UIControlStateNormal];
		repeatOne = YES;
		repeatAll = NO;
        [JJAudioPlayerManager sharedManager].playerMode = JJAudioPlayerModeRepeatOne;
	}
	else
	{
		[repeatButton setImage:[UIImage imageNamed:@"AudioPlayerRepeatOn"]
					  forState:UIControlStateNormal];
		repeatOne = NO;
		repeatAll = YES;
        [JJAudioPlayerManager sharedManager].playerMode = JJAudioPlayerModeSequenceLoop;
	}
	
	[self updateViewForPlayerInfo:player];
	[self updateViewForPlayerState:player];
}

- (BOOL)canGoToNextTrack
{
	return [[JJAudioPlayerManager sharedManager] canGoNextTrack];
}

- (BOOL)canGoToPreviousTrack
{
	return [[JJAudioPlayerManager sharedManager] canGoPreviouseTrack];
}

-(void)play
{
	if (self.player.playing == YES) 
	{
		[self.player pause];
	}
	else
	{
		if ([self playMusic])
		{
			
		}
		else
		{
			NSLog(@"Could not play %@\n", self.player.url);
		}
	}
	
	
	[self updateViewForPlayerInfo:player];
	[self updateViewForPlayerState:player];
}

- (void)previous
{
		
	AVAudioPlayer *newAudioPlayer =[[JJAudioPlayerManager sharedManager] playerForPreviousMusic];
	
	[self stopMusic];
	self.player = newAudioPlayer;
	
	self.player.delegate = self;
	self.player.volume = volumeSlider.value;
	[self.player prepareToPlay];
	[self.player setNumberOfLoops:0];
	[self playMusic];
	
    selectedIndex = [[JJAudioPlayerManager sharedManager] currentIndex];
	[self updateViewForPlayerInfo:player];
	[self updateViewForPlayerState:player];	
}

- (void)next
{
	AVAudioPlayer *newAudioPlayer =[[JJAudioPlayerManager sharedManager] playerForNextMusic];

	[self stopMusic];
	self.player = newAudioPlayer;
	
	self.player.delegate = self;
	self.player.volume = volumeSlider.value;
	[self.player prepareToPlay];
	[self.player setNumberOfLoops:0];
	[self playMusic];
	
    selectedIndex = [[JJAudioPlayerManager sharedManager] currentIndex];
	[self updateViewForPlayerInfo:player];
	[self updateViewForPlayerState:player];
}

- (void)volumeSliderMoved:(UISlider *)sender
{
	self.player.volume = [sender value];
	[[NSUserDefaults standardUserDefaults] setFloat:[sender value] forKey:@"PlayerVolume"];
}

static BOOL SliderValueIsChanging = NO;

- (void)progressSliderMoved:(UISlider *)sender
{
	[self updateCurrentTime:sender.value duration:self.player.duration];
}

-(void)startChangeSliderValue:(UISlider*)sender{
    SliderValueIsChanging = YES;
}

-(void)endChangeSliderValue:(UISlider*)sender{
    self.player.currentTime = sender.value;
	[self updateCurrentTime:self.player.currentTime duration:self.player.duration];
    SliderValueIsChanging = NO;
}

-(void)cancelChangeSliderValue:(UISlider*)sender{
    self.player.currentTime = sender.value;
	[self updateCurrentTime:self.player.currentTime duration:self.player.duration];
    SliderValueIsChanging = NO;
}

#pragma mark -
#pragma mark AVAudioPlayer delegate


- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)p successfully:(BOOL)flag
{
	if (flag == NO)
		NSLog(@"Playback finished unsuccessfully");
	
	if ([self canGoToNextTrack])
		 [self next];
	else if (interrupted)
		[self playMusic];
	else
		[self stopMusic];
		 
	[self updateViewForPlayerInfo:player];
	[self updateViewForPlayerState:player];
}

- (void)playerDecodeErrorDidOccur:(AVAudioPlayer *)p error:(NSError *)error
{
	NSLog(@"ERROR IN DECODE: %@\n", error);
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Decode Error" 
														message:[NSString stringWithFormat:@"Unable to decode audio file with error: %@", [error localizedDescription]] 
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
	[alertView show];
}

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{
	// perform any interruption handling here
	NSLog(@"(apbi) Interruption Detected\n");
	[[NSUserDefaults standardUserDefaults] setFloat:[self.player currentTime] forKey:@"Interruption"];
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player
{
	// resume playback at the end of the interruption
	NSLog(@"(apei) Interruption ended\n");
	[self playMusic];
	
	// remove the interruption key. it won't be needed
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Interruption"];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
//	self.player = nil;
    [self restoreNavigationBarStatus];
    [self.navigationController setNavigationBarHidden:_previousNavigationBarHidden animated:YES];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView 
{
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section 
{	
    return [self.playList count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
    static NSString *CellIdentifier = @"Cell";
    
    MDAudioPlayerTableViewCell *cell = (MDAudioPlayerTableViewCell *)[aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
        cell = [[MDAudioPlayerTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}
	
	cell.title = [[self.playList objectAtIndex:indexPath.row] title];
	cell.number = [NSString stringWithFormat:@"%d.", (indexPath.row + 1)];
	cell.duration = [[self.playList objectAtIndex:indexPath.row] durationInMinutes];

	cell.isEven = indexPath.row % 2;
	
	if (selectedIndex == indexPath.row)
		cell.isSelectedIndex = YES;
	else
		cell.isSelectedIndex = NO;
	
	return cell;
}


- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
	
	selectedIndex = indexPath.row;
	
	for (MDAudioPlayerTableViewCell *cell in [aTableView visibleCells])
	{
		cell.isSelectedIndex = NO;
	}
	
	MDAudioPlayerTableViewCell *cell = (MDAudioPlayerTableViewCell *)[aTableView cellForRowAtIndexPath:indexPath];
	cell.isSelectedIndex = YES;
	
	AVAudioPlayer *newAudioPlayer =[self audioPlayerForMusicAtIndex:selectedIndex];
	
	[self stopMusic];
	self.player = newAudioPlayer;
	
	self.player.delegate = self;
	self.player.volume = volumeSlider.value;
	[self.player prepareToPlay];
	[self.player setNumberOfLoops:0];
	[self playMusic];
	
	[self updateViewForPlayerInfo:self.player];
	[self updateViewForPlayerState:self.player];
}

- (BOOL)tableView:(UITableView *)table canEditRowAtIndexPath:(NSIndexPath *)indexPath 
{
	return NO;
}


- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 44;
}


#pragma mark - Image Reflection

CGImageRef CreateGradientImage(int pixelsWide, int pixelsHigh)
{
	CGImageRef theCGImage = NULL;
	
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
	
	CGContextRef gradientBitmapContext = CGBitmapContextCreate(NULL, pixelsWide, pixelsHigh,
															   8, 0, colorSpace, kCGImageAlphaNone);

	CGFloat colors[] = {0.0, 1.0, 1.0, 1.0};
	
	CGGradientRef grayScaleGradient = CGGradientCreateWithColorComponents(colorSpace, colors, NULL, 2);
	CGColorSpaceRelease(colorSpace);
	
	CGPoint gradientStartPoint = CGPointZero;
	CGPoint gradientEndPoint = CGPointMake(0, pixelsHigh);
	
	CGContextDrawLinearGradient(gradientBitmapContext, grayScaleGradient, gradientStartPoint,
								gradientEndPoint, kCGGradientDrawsAfterEndLocation);
	CGGradientRelease(grayScaleGradient);
	
	theCGImage = CGBitmapContextCreateImage(gradientBitmapContext);
	CGContextRelease(gradientBitmapContext);
	
    return theCGImage;
}

CGContextRef MyCreateBitmapContext(int pixelsWide, int pixelsHigh)
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
	// create the bitmap context
	CGContextRef bitmapContext = CGBitmapContextCreate (NULL, pixelsWide, pixelsHigh, 8,
														0, colorSpace,
														// this will give us an optimal BGRA format for the device:
														(kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst));
	CGColorSpaceRelease(colorSpace);
	
    return bitmapContext;
}

- (UIImage *)reflectedImage:(UIButton *)fromImage withHeight:(NSUInteger)height
{
    if (height == 0)
		return nil;
    
	// create a bitmap graphics context the size of the image
	CGContextRef mainViewContentContext = MyCreateBitmapContext(fromImage.bounds.size.width, height);
	
	CGImageRef gradientMaskImage = CreateGradientImage(1, height);
	
	CGContextClipToMask(mainViewContentContext, CGRectMake(0.0, 0.0, fromImage.bounds.size.width, height), gradientMaskImage);
	CGImageRelease(gradientMaskImage);

	CGContextTranslateCTM(mainViewContentContext, 0.0, height);
	CGContextScaleCTM(mainViewContentContext, 1.0, -1.0);
	
	CGContextDrawImage(mainViewContentContext, fromImage.bounds, fromImage.imageView.image.CGImage);
	
	CGImageRef reflectionImage = CGBitmapContextCreateImage(mainViewContentContext);
	CGContextRelease(mainViewContentContext);
	
	UIImage *theImage = [UIImage imageWithCGImage:reflectionImage];
	
	CGImageRelease(reflectionImage);
	
	return theImage;
}

- (void)viewDidUnload
{
	self.reflectionView = nil;
}

-(AVAudioPlayer*)audioPlayerForMusicAtIndex:(NSInteger)index{
    AVAudioPlayer* audioPlayer = [[JJAudioPlayerManager sharedManager] playerForMusicAtIndex:index inPlayList:self.playList];
    audioPlayer.delegate = self;
    return audioPlayer;
}

-(BOOL)playMusic{
    BOOL result = [self.player play];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    return result;
}

-(void)stopMusic{
    [self.player stop];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}

#pragma mark - audio session delegate
- (void)beginInterruption{
    NSLog(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}/* something has caused your audio session to be interrupted */

/* the interruption is over */
- (void)endInterruptionWithFlags:(NSUInteger)flags NS_AVAILABLE_IOS(4_0){
    NSLog(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}/* Currently the only flag is AVAudioSessionInterruptionFlags_ShouldResume. */

- (void)endInterruption{
    NSLog(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}/* endInterruptionWithFlags: will be called instead if implemented. */

/* notification for input become available or unavailable */
- (void)inputIsAvailableChanged:(BOOL)isInputAvailable{
    NSLog(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}

#pragma mark - notification
-(void)didBecomeActive:(NSNotification*)notification{
    JJAudioPlayerManager* audioManager = [JJAudioPlayerManager sharedManager];
    self.player = [audioManager currentPlayer];
    self.playList = [NSMutableArray arrayWithArray:[audioManager currentPlayList]];
    selectedIndex = [audioManager currentIndex];
    
    [self updateViewForPlayerInfo:self.player];
    [self updateViewForPlayerState:self.player];
}

@end
    