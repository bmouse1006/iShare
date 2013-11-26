//
//	ReaderMainPagebar.m
//	Reader v2.5.6
//
//	Created by Julius Oklamcak on 2011-09-01.
//	Copyright © 2011-2012 Julius Oklamcak. All rights reserved.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights to
//	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
//	of the Software, and to permit persons to whom the Software is furnished to
//	do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "ReaderMainPagebar.h"
#import "ReaderThumbCache.h"
#import "ReaderDocument.h"

#import <QuartzCore/QuartzCore.h>

@interface ReaderMainPagebar()

@property (nonatomic, strong) ReaderDocument* document;
@property (nonatomic, strong) ReaderTrackControl* trackControl;
@property (nonatomic, strong) NSMutableDictionary* miniThumbViews;
@property (nonatomic, strong) ReaderPagebarThumb* pageThumbView;
@property (nonatomic, strong) UILabel* pageNumberLabel;
@property (nonatomic, strong) UIView* pageNumberView;
@property (nonatomic, weak) NSTimer* enableTimer;
@property (nonatomic, weak) NSTimer* trackTimer;

@end

@implementation ReaderMainPagebar

#pragma mark Constants

#define THUMB_SMALL_GAP 2
#define THUMB_SMALL_WIDTH 22
#define THUMB_SMALL_HEIGHT 28

#define THUMB_LARGE_WIDTH 32
#define THUMB_LARGE_HEIGHT 42

#define PAGE_NUMBER_WIDTH 96.0f
#define PAGE_NUMBER_HEIGHT 30.0f
#define PAGE_NUMBER_SPACE 20.0f

#pragma mark Properties

@synthesize delegate;

#pragma mark ReaderMainPagebar class methods

+ (Class)layerClass
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	return [CAGradientLayer class];
}

#pragma mark ReaderMainPagebar instance methods

- (id)initWithFrame:(CGRect)frame
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	return [self initWithFrame:frame document:nil];
}

- (void)updatePageThumbView:(NSInteger)page
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	NSInteger pages = [self.document.pageCount integerValue];

	if (pages > 1) // Only update frame if more than one page
	{
		CGFloat controlWidth = self.trackControl.bounds.size.width;

		CGFloat useableWidth = (controlWidth - THUMB_LARGE_WIDTH);

		CGFloat stride = (useableWidth / (pages - 1)); // Page stride

		NSInteger X = (stride * (page - 1)); CGFloat pageThumbX = X;

		CGRect pageThumbRect = self.pageThumbView.frame; // Current frame

		if (pageThumbX != pageThumbRect.origin.x) // Only if different
		{
			pageThumbRect.origin.x = pageThumbX; // The new X position

			self.pageThumbView.frame = pageThumbRect; // Update the frame
		}
	}

	if (page != self.pageThumbView.tag) // Only if page number changed
	{
		self.pageThumbView.tag = page; [self.pageThumbView reuse]; // Reuse the thumb view

		CGSize size = CGSizeMake(THUMB_LARGE_WIDTH, THUMB_LARGE_HEIGHT); // Maximum thumb size

		NSURL *fileURL = self.document.fileURL; NSString *guid = self.document.guid; NSString *phrase = self.document.password;

		ReaderThumbRequest *request = [ReaderThumbRequest forView:self.pageThumbView fileURL:fileURL password:phrase guid:guid page:page size:size];

		UIImage *image = [[ReaderThumbCache sharedInstance] thumbRequest:request priority:YES]; // Request the thumb

		UIImage *thumb = ([image isKindOfClass:[UIImage class]] ? image : nil); [self.pageThumbView showImage:thumb];
	}
}

- (void)updatePageNumberText:(NSInteger)page
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (page != self.pageNumberLabel.tag) // Only if page number changed
	{
		NSInteger pages = [self.document.pageCount integerValue]; // Total pages

		NSString *format = NSLocalizedStringFromTable(@"%d of %d",@"PDFReaderLocalizable", @"format"); // Format

		NSString *number = [NSString stringWithFormat:format, page, pages]; // Text

		self.pageNumberLabel.text = number; // Update the page number label text

		self.pageNumberLabel.tag = page; // Update the last page number tag
	}
}

- (id)initWithFrame:(CGRect)frame document:(ReaderDocument *)object
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	assert(object != nil); // Check

	if ((self = [super initWithFrame:frame]))
	{
		self.autoresizesSubviews = YES;
		self.userInteractionEnabled = YES;
		self.contentMode = UIViewContentModeRedraw;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
		self.backgroundColor = [UIColor clearColor];

		CAGradientLayer *layer = (CAGradientLayer *)self.layer;
		UIColor *liteColor = [UIColor colorWithWhite:0.82f alpha:0.8f];
		UIColor *darkColor = [UIColor colorWithWhite:0.32f alpha:0.8f];
		layer.colors = [NSArray arrayWithObjects:(id)liteColor.CGColor, (id)darkColor.CGColor, nil];

		CGRect shadowRect = self.bounds; shadowRect.size.height = 4.0f; shadowRect.origin.y -= shadowRect.size.height;

		ReaderPagebarShadow *shadowView = [[ReaderPagebarShadow alloc] initWithFrame:shadowRect];

		[self addSubview:shadowView]; // Add the shadow to the view

		CGFloat numberY = (0.0f - (PAGE_NUMBER_HEIGHT + PAGE_NUMBER_SPACE));
		CGFloat numberX = ((self.bounds.size.width - PAGE_NUMBER_WIDTH) / 2.0f);
		CGRect numberRect = CGRectMake(numberX, numberY, PAGE_NUMBER_WIDTH, PAGE_NUMBER_HEIGHT);

		self.pageNumberView = [[UIView alloc] initWithFrame:numberRect]; // Page numbers view

		self.pageNumberView.autoresizesSubviews = NO;
		self.pageNumberView.userInteractionEnabled = NO;
		self.pageNumberView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		self.pageNumberView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.4f];

		//pageNumberView.layer.cornerRadius = 4.0f;
		self.pageNumberView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
		self.pageNumberView.layer.shadowColor = [UIColor colorWithWhite:0.0f alpha:0.6f].CGColor;
		self.pageNumberView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.pageNumberView.bounds].CGPath;
		self.pageNumberView.layer.shadowRadius = 2.0f; self.pageNumberView.layer.shadowOpacity = 1.0f;

		CGRect textRect = CGRectInset(self.pageNumberView.bounds, 4.0f, 2.0f); // Inset the text a bit

		self.pageNumberLabel = [[UILabel alloc] initWithFrame:textRect]; // Page numbers label

		self.pageNumberLabel.autoresizesSubviews = NO;
		self.pageNumberLabel.autoresizingMask = UIViewAutoresizingNone;
		self.pageNumberLabel.textAlignment = NSTextAlignmentCenter;
		self.pageNumberLabel.backgroundColor = [UIColor clearColor];
		self.pageNumberLabel.textColor = [UIColor whiteColor];
		self.pageNumberLabel.font = [UIFont systemFontOfSize:16.0f];
		self.pageNumberLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		self.pageNumberLabel.shadowColor = [UIColor blackColor];
		self.pageNumberLabel.adjustsFontSizeToFitWidth = YES;
		self.pageNumberLabel.minimumScaleFactor = 12.0f;

		[self.pageNumberView addSubview:self.pageNumberLabel]; // Add label view

		[self addSubview:self.pageNumberView]; // Add page numbers display view

		self.trackControl = [[ReaderTrackControl alloc] initWithFrame:self.bounds]; // Track control view

		[self.trackControl addTarget:self action:@selector(trackViewTouchDown:) forControlEvents:UIControlEventTouchDown];
		[self.trackControl addTarget:self action:@selector(trackViewValueChanged:) forControlEvents:UIControlEventValueChanged];
		[self.trackControl addTarget:self action:@selector(trackViewTouchUp:) forControlEvents:UIControlEventTouchUpOutside];
		[self.trackControl addTarget:self action:@selector(trackViewTouchUp:) forControlEvents:UIControlEventTouchUpInside];

		[self addSubview:self.trackControl]; // Add the track control and thumbs view

		self.document = object; // Retain the document object for our use

		[self updatePageNumberText:[self.document.pageNumber integerValue]];

		self.miniThumbViews = [NSMutableDictionary new]; // Small thumbs
	}

	return self;
}

- (void)removeFromSuperview
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[self.trackTimer invalidate];
    [self.enableTimer invalidate];

	[super removeFromSuperview];
}

- (void)dealloc
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif
}

- (void)layoutSubviews
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	CGRect controlRect = CGRectInset(self.bounds, 4.0f, 0.0f);

	CGFloat thumbWidth = (THUMB_SMALL_WIDTH + THUMB_SMALL_GAP);

	NSInteger thumbs = (controlRect.size.width / thumbWidth);

	NSInteger pages = [self.document.pageCount integerValue]; // Pages

	if (thumbs > pages) thumbs = pages; // No more than total pages

	CGFloat controlWidth = ((thumbs * thumbWidth) - THUMB_SMALL_GAP);

	controlRect.size.width = controlWidth; // Update control width

	CGFloat widthDelta = (self.bounds.size.width - controlWidth);

	NSInteger X = (widthDelta / 2.0f); controlRect.origin.x = X;

	self.trackControl.frame = controlRect; // Update track control frame

	if (self.pageThumbView == nil) // Create the page thumb view when needed
	{
		CGFloat heightDelta = (controlRect.size.height - THUMB_LARGE_HEIGHT);

		NSInteger thumbY = (heightDelta / 2.0f); NSInteger thumbX = 0; // Thumb X, Y

		CGRect thumbRect = CGRectMake(thumbX, thumbY, THUMB_LARGE_WIDTH, THUMB_LARGE_HEIGHT);

		self.pageThumbView = [[ReaderPagebarThumb alloc] initWithFrame:thumbRect]; // Create the thumb view

		self.pageThumbView.layer.zPosition = 1.0f; // Z position so that it sits on top of the small thumbs

		[self.trackControl addSubview:self.pageThumbView]; // Add as the first subview of the track control
	}

	[self updatePageThumbView:[self.document.pageNumber integerValue]]; // Update page thumb view

	NSInteger strideThumbs = (thumbs - 1); if (strideThumbs < 1) strideThumbs = 1;

	CGFloat stride = ((CGFloat)pages / (CGFloat)strideThumbs); // Page stride

	CGFloat heightDelta = (controlRect.size.height - THUMB_SMALL_HEIGHT);

	NSInteger thumbY = (heightDelta / 2.0f); NSInteger thumbX = 0; // Initial X, Y

	CGRect thumbRect = CGRectMake(thumbX, thumbY, THUMB_SMALL_WIDTH, THUMB_SMALL_HEIGHT);

	NSMutableDictionary *thumbsToHide = [self.miniThumbViews mutableCopy];

	for (NSInteger thumb = 0; thumb < thumbs; thumb++) // Iterate through needed thumbs
	{
		NSInteger page = ((stride * thumb) + 1); if (page > pages) page = pages; // Page

		NSNumber *key = [NSNumber numberWithInteger:page]; // Page number key for thumb view

		ReaderPagebarThumb *smallThumbView = [self.miniThumbViews objectForKey:key]; // Thumb view

		if (smallThumbView == nil) // We need to create a new small thumb view for the page number
		{
			CGSize size = CGSizeMake(THUMB_SMALL_WIDTH, THUMB_SMALL_HEIGHT); // Maximum thumb size

			NSURL *fileURL = self.document.fileURL; NSString *guid = self.document.guid; NSString *phrase = self.document.password;

			smallThumbView = [[ReaderPagebarThumb alloc] initWithFrame:thumbRect small:YES]; // Create a small thumb view

			ReaderThumbRequest *thumbRequest = [ReaderThumbRequest forView:smallThumbView fileURL:fileURL password:phrase guid:guid page:page size:size];

			UIImage *image = [[ReaderThumbCache sharedInstance] thumbRequest:thumbRequest priority:NO]; // Request the thumb

			if ([image isKindOfClass:[UIImage class]]) [smallThumbView showImage:image]; // Use thumb image from cache

			[self.trackControl addSubview:smallThumbView]; [self.miniThumbViews setObject:smallThumbView forKey:key];
		}
		else // Resue existing small thumb view for the page number
		{
			smallThumbView.hidden = NO; [thumbsToHide removeObjectForKey:key];

			if (CGRectEqualToRect(smallThumbView.frame, thumbRect) == false)
			{
				smallThumbView.frame = thumbRect; // Update thumb frame
			}
		}

		thumbRect.origin.x += thumbWidth; // Next thumb X position
	}

	[thumbsToHide enumerateKeysAndObjectsUsingBlock: // Hide unused thumbs
		^(id key, id object, BOOL *stop)
		{
			ReaderPagebarThumb *thumb = object; thumb.hidden = YES;
		}
	];
}

- (void)updatePagebarViews
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	NSInteger page = [self.document.pageNumber integerValue]; // #

	[self updatePageNumberText:page]; // Update page number text

	[self updatePageThumbView:page]; // Update page thumb view
}

- (void)updatePagebar
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (self.hidden == NO) // Only if visible
	{
		[self updatePagebarViews]; // Update views
	}
}

- (void)hidePagebar
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (self.hidden == NO) // Only if visible
	{
		[UIView animateWithDuration:0.25 delay:0.0
			options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
			animations:^(void)
			{
				self.alpha = 0.0f;
			}
			completion:^(BOOL finished)
			{
				self.hidden = YES;
			}
		];
	}
}

- (void)showPagebar
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (self.hidden == YES) // Only if hidden
	{
		[self updatePagebarViews]; // Update views first

		[UIView animateWithDuration:0.25 delay:0.0
			options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
			animations:^(void)
			{
				self.hidden = NO;
				self.alpha = 1.0f;
			}
			completion:NULL
		];
	}
}

#pragma mark ReaderTrackControl action methods

- (void)trackTimerFired:(NSTimer *)timer
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[self.trackTimer invalidate]; // Cleanup

	if (self.trackControl.tag != [self.document.pageNumber integerValue]) // Only if different
	{
		[delegate pagebar:self gotoPage:self.trackControl.tag]; // Go to document page
	}
}

- (void)enableTimerFired:(NSTimer *)timer
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[self.enableTimer invalidate]; // Cleanup

	self.trackControl.userInteractionEnabled = YES; // Enable track control interaction
}

- (void)restartTrackTimer
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (self.trackTimer != nil) { [self.trackTimer invalidate]; } // Invalidate and release previous timer

	self.trackTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(trackTimerFired:) userInfo:nil repeats:NO];
}

- (void)startEnableTimer
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (self.enableTimer != nil) {
        [self.enableTimer invalidate];
    } // Invalidate and release previous timer

	self.enableTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(enableTimerFired:) userInfo:nil repeats:NO];
}

- (NSInteger)trackViewPageNumber:(ReaderTrackControl *)trackView
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	CGFloat controlWidth = trackView.bounds.size.width; // View width

	CGFloat stride = (controlWidth / [self.document.pageCount integerValue]);

	NSInteger page = (trackView.value / stride); // Integer page number

	return (page + 1); // + 1
}

- (void)trackViewTouchDown:(ReaderTrackControl *)trackView
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	NSInteger page = [self trackViewPageNumber:trackView]; // Page

	if (page != [self.document.pageNumber integerValue]) // Only if different
	{
		[self updatePageNumberText:page]; // Update page number text

		[self updatePageThumbView:page]; // Update page thumb view

		[self restartTrackTimer]; // Start the track timer
	}

	trackView.tag = page; // Start page tracking
}

- (void)trackViewValueChanged:(ReaderTrackControl *)trackView
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	NSInteger page = [self trackViewPageNumber:trackView]; // Page

	if (page != trackView.tag) // Only if the page number has changed
	{
		[self updatePageNumberText:page]; // Update page number text

		[self updatePageThumbView:page]; // Update page thumb view

		trackView.tag = page; // Update the page tracking tag

		[self restartTrackTimer]; // Restart the track timer
	}
}

- (void)trackViewTouchUp:(ReaderTrackControl *)trackView
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[self.trackTimer invalidate];  // Cleanup

	if (trackView.tag != [self.document.pageNumber integerValue]) // Only if different
	{
		trackView.userInteractionEnabled = NO; // Disable track control interaction

		[delegate pagebar:self gotoPage:trackView.tag]; // Go to document page

		[self startEnableTimer]; // Start track control enable timer
	}

	trackView.tag = 0; // Reset page tracking
}

@end

#pragma mark -

//
//	ReaderTrackControl class implementation
//

@implementation ReaderTrackControl

#pragma mark Properties

@synthesize value = _value;

#pragma mark ReaderTrackControl instance methods

- (id)initWithFrame:(CGRect)frame
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if ((self = [super initWithFrame:frame]))
	{
		self.autoresizesSubviews = NO;
		self.userInteractionEnabled = YES;
		self.contentMode = UIViewContentModeRedraw;
		self.autoresizingMask = UIViewAutoresizingNone;
		self.backgroundColor = [UIColor clearColor];
	}

	return self;
}

- (void)dealloc
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif
}

- (CGFloat)limitValue:(CGFloat)valueX
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	CGFloat minX = self.bounds.origin.x; // 0.0f;
	CGFloat maxX = (self.bounds.size.width - 1.0f);

	if (valueX < minX) valueX = minX; // Minimum X
	if (valueX > maxX) valueX = maxX; // Maximum X

	return valueX;
}

#pragma mark UIControl subclass methods

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	CGPoint point = [touch locationInView:self]; // Touch point

	_value = [self limitValue:point.x]; // Limit control value

	return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (self.touchInside == YES) // Only if inside the control
	{
		CGPoint point = [touch locationInView:touch.view]; // Touch point

		CGFloat x = [self limitValue:point.x]; // Potential new control value

		if (x != _value) // Only if the new value has changed since the last time
		{
			_value = x; [self sendActionsForControlEvents:UIControlEventValueChanged];
		}
	}

	return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	CGPoint point = [touch locationInView:self]; // Touch point

	_value = [self limitValue:point.x]; // Limit control value
}

@end

#pragma mark -

//
//	ReaderPagebarThumb class implementation
//

@implementation ReaderPagebarThumb

//#pragma mark Properties

//@synthesize ;

#pragma mark ReaderPagebarThumb instance methods

- (id)initWithFrame:(CGRect)frame
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	return [self initWithFrame:frame small:NO];
}

- (id)initWithFrame:(CGRect)frame small:(BOOL)small
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if ((self = [super initWithFrame:frame])) // Superclass init
	{
		CGFloat value = (small ? 0.6f : 0.7f); // Size based alpha value

		UIColor *background = [UIColor colorWithWhite:0.8f alpha:value];

		self.backgroundColor = background; imageView.backgroundColor = background;

		imageView.layer.borderColor = [UIColor colorWithWhite:0.4f alpha:0.6f].CGColor;

		imageView.layer.borderWidth = 1.0f; // Give the thumb image view a border
	}

	return self;
}

- (void)dealloc
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif
}

@end

#pragma mark -

//
//	ReaderPagebarShadow class implementation
//

@implementation ReaderPagebarShadow

//#pragma mark Properties

//@synthesize ;

#pragma mark ReaderPagebarShadow class methods

+ (Class)layerClass
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	return [CAGradientLayer class];
}

#pragma mark ReaderPagebarShadow instance methods

- (id)initWithFrame:(CGRect)frame
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if ((self = [super initWithFrame:frame]))
	{
		self.autoresizesSubviews = NO;
		self.userInteractionEnabled = NO;
		self.contentMode = UIViewContentModeRedraw;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.backgroundColor = [UIColor clearColor];

		CAGradientLayer *layer = (CAGradientLayer *)self.layer;
		UIColor *blackColor = [UIColor colorWithWhite:0.42f alpha:1.0f];
		UIColor *clearColor = [UIColor colorWithWhite:0.42f alpha:0.0f];
		layer.colors = [NSArray arrayWithObjects:(id)clearColor.CGColor, (id)blackColor.CGColor, nil];
	}

	return self;
}

- (void)dealloc
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif
}

@end
