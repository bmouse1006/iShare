//
//	ReaderViewController.m
//	Reader v2.5.5
//
//	Created by Julius Oklamcak on 2011-07-01.
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

#import "ReaderConstants.h"
#import "ReaderViewController.h"
#import "ReaderThumbCache.h"
#import "ReaderThumbQueue.h"

@implementation ReaderViewController

#pragma mark Constants

#define PAGING_VIEWS 3

#define TOOLBAR_HEIGHT 44.0f
#define PAGEBAR_HEIGHT 48.0f

#define TAP_AREA_SIZE 48.0f

#pragma mark Properties

@synthesize delegate;

#pragma mark Support methods

- (void)updateScrollViewContentSize
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	NSInteger count = [self.document.pageCount integerValue];

	if (count > PAGING_VIEWS) count = PAGING_VIEWS; // Limit

	CGFloat contentHeight = self.theScrollView.bounds.size.height;

	CGFloat contentWidth = (self.theScrollView.bounds.size.width * count);

	self.theScrollView.contentSize = CGSizeMake(contentWidth, contentHeight);
}

- (void)updateScrollViewContentViews
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[self updateScrollViewContentSize]; // Update the content size

	NSMutableIndexSet *pageSet = [NSMutableIndexSet indexSet]; // Page set

	[self.contentViews enumerateKeysAndObjectsUsingBlock: // Enumerate content views
		^(id key, id object, BOOL *stop)
		{
			ReaderContentView *contentView = object; [pageSet addIndex:contentView.tag];
		}
	];

	__block CGRect viewRect = CGRectZero; viewRect.size = self.theScrollView.bounds.size;

	__block CGPoint contentOffset = CGPointZero; NSInteger page = [self.document.pageNumber integerValue];

	[pageSet enumerateIndexesUsingBlock: // Enumerate page number set
		^(NSUInteger number, BOOL *stop)
		{
			NSNumber *key = [NSNumber numberWithInteger:number]; // # key

			ReaderContentView *contentView = [self.contentViews objectForKey:key];

			contentView.frame = viewRect; if (page == number) contentOffset = viewRect.origin;

			viewRect.origin.x += viewRect.size.width; // Next view frame position
		}
	];

	if (CGPointEqualToPoint(self.theScrollView.contentOffset, contentOffset) == false)
	{
		self.theScrollView.contentOffset = contentOffset; // Update content offset
	}
}

- (void)updateToolbarBookmarkIcon
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	NSInteger page = [self.document.pageNumber integerValue];

	BOOL bookmarked = [self.document.bookmarks containsIndex:page];

	[self.mainToolbar setBookmarkState:bookmarked]; // Update
}

- (void)showDocumentPage:(NSInteger)page
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (page != currentPage) // Only if different
	{
		NSInteger minValue; NSInteger maxValue;
		NSInteger maxPage = [self.document.pageCount integerValue];
		NSInteger minPage = 1;

		if ((page < minPage) || (page > maxPage)) return;

		if (maxPage <= PAGING_VIEWS) // Few pages
		{
			minValue = minPage;
			maxValue = maxPage;
		}
		else // Handle more pages
		{
			minValue = (page - 1);
			maxValue = (page + 1);

			if (minValue < minPage)
				{minValue++; maxValue++;}
			else
				if (maxValue > maxPage)
					{minValue--; maxValue--;}
		}

		NSMutableIndexSet *newPageSet = [NSMutableIndexSet new];

		NSMutableDictionary *unusedViews = [self.contentViews mutableCopy];

		CGRect viewRect = CGRectZero; viewRect.size = self.theScrollView.bounds.size;

		for (NSInteger number = minValue; number <= maxValue; number++)
		{
			NSNumber *key = [NSNumber numberWithInteger:number]; // # key

			ReaderContentView *contentView = [self.contentViews objectForKey:key];

			if (contentView == nil) // Create a brand new document content view
			{
				NSURL *fileURL = self.document.fileURL; NSString *phrase = self.document.password; // Document properties

				contentView = [[ReaderContentView alloc] initWithFrame:viewRect fileURL:fileURL page:number password:phrase];

				[self.theScrollView addSubview:contentView]; [self.contentViews setObject:contentView forKey:key];

				contentView.message = self; [newPageSet addIndex:number];
			}
			else // Reposition the existing content view
			{
				contentView.frame = viewRect; [contentView zoomReset];

				[unusedViews removeObjectForKey:key];
			}

			viewRect.origin.x += viewRect.size.width;
		}

		[unusedViews enumerateKeysAndObjectsUsingBlock: // Remove unused views
			^(id key, id object, BOOL *stop)
			{
				[self.contentViews removeObjectForKey:key];

				ReaderContentView *contentView = object;

				[contentView removeFromSuperview];
			}
		];

		CGFloat viewWidthX1 = viewRect.size.width;
		CGFloat viewWidthX2 = (viewWidthX1 * 2.0f);

		CGPoint contentOffset = CGPointZero;

		if (maxPage >= PAGING_VIEWS)
		{
			if (page == maxPage)
				contentOffset.x = viewWidthX2;
			else
				if (page != minPage)
					contentOffset.x = viewWidthX1;
		}
		else
			if (page == (PAGING_VIEWS - 1))
				contentOffset.x = viewWidthX1;

		if (CGPointEqualToPoint(self.theScrollView.contentOffset, contentOffset) == false)
		{
			self.theScrollView.contentOffset = contentOffset; // Update content offset
		}

		if ([self.document.pageNumber integerValue] != page) // Only if different
		{
			self.document.pageNumber = [NSNumber numberWithInteger:page]; // Update page number
		}

		NSURL *fileURL = self.document.fileURL; NSString *phrase = self.document.password; NSString *guid = self.document.guid;

		if ([newPageSet containsIndex:page] == YES) // Preview visible page first
		{
			NSNumber *key = [NSNumber numberWithInteger:page]; // # key

			ReaderContentView *targetView = [self.contentViews objectForKey:key];

			[targetView showPageThumb:fileURL page:page password:phrase guid:guid];

			[newPageSet removeIndex:page]; // Remove visible page from set
		}

		[newPageSet enumerateIndexesWithOptions:NSEnumerationReverse usingBlock: // Show previews
			^(NSUInteger number, BOOL *stop)
			{
				NSNumber *key = [NSNumber numberWithInteger:number]; // # key

				ReaderContentView *targetView = [self.contentViews objectForKey:key];

				[targetView showPageThumb:fileURL page:number password:phrase guid:guid];
			}
		];

		[self.mainPagebar updatePagebar]; // Update the pagebar display

		[self updateToolbarBookmarkIcon]; // Update bookmark

		currentPage = page; // Track current page number
	}
}

- (void)showDocument:(id)object
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[self updateScrollViewContentSize]; // Set content size

	[self showDocumentPage:[self.document.pageNumber integerValue]]; // Show

	self.document.lastOpen = [NSDate date]; // Update last opened date

	isVisible = YES; // iOS present modal bodge
}

#pragma mark UIViewController methods

- (id)initWithReaderDocument:(ReaderDocument *)object
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	id reader = nil; // ReaderViewController object

	if ((object != nil) && ([object isKindOfClass:[ReaderDocument class]]))
	{
		if ((self = [super initWithNibName:nil bundle:nil])) // Designated initializer
		{
			NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

			[notificationCenter addObserver:self selector:@selector(applicationWill:) name:UIApplicationWillTerminateNotification object:nil];

			[notificationCenter addObserver:self selector:@selector(applicationWill:) name:UIApplicationWillResignActiveNotification object:nil];

			[object updateProperties]; self.document = object; // Retain the supplied ReaderDocument object for our use

			[ReaderThumbCache touchThumbCacheWithGUID:object.guid]; // Touch the document thumb cache directory

			reader = self; // Return an initialized ReaderViewController object
		}
	}

	return reader;
}

/*
- (void)loadView
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	// Implement loadView to create a view hierarchy programmatically, without using a nib.
}
*/

- (void)viewDidLoad
{
#ifdef DEBUGX
	NSLog(@"%s %@", __FUNCTION__, NSStringFromCGRect(self.view.bounds));
#endif

	[super viewDidLoad];

	NSAssert(!(self.document == nil), @"ReaderDocument == nil");

	assert(self.splitViewController == nil); // Not supported (sorry)

//	self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];

	CGRect viewRect = self.view.bounds; // View controller's view bounds

	self.theScrollView = [[UIScrollView alloc] initWithFrame:viewRect]; // All

	self.theScrollView.scrollsToTop = NO;
	self.theScrollView.pagingEnabled = YES;
	self.theScrollView.delaysContentTouches = NO;
	self.theScrollView.showsVerticalScrollIndicator = NO;
	self.theScrollView.showsHorizontalScrollIndicator = NO;
	self.theScrollView.contentMode = UIViewContentModeRedraw;
	self.theScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.theScrollView.backgroundColor = [UIColor clearColor];
	self.theScrollView.userInteractionEnabled = YES;
	self.theScrollView.autoresizesSubviews = NO;
	self.theScrollView.delegate = self;

	[self.view addSubview:self.theScrollView];

	CGRect toolbarRect = viewRect;
	toolbarRect.size.height = TOOLBAR_HEIGHT;

	self.mainToolbar = [[ReaderMainToolbar alloc] initWithFrame:toolbarRect document:self.document]; // At top

	self.mainToolbar.delegate = self;

	[self.view addSubview:self.mainToolbar];

	CGRect pagebarRect = viewRect;
	pagebarRect.size.height = PAGEBAR_HEIGHT;
	pagebarRect.origin.y = (viewRect.size.height - PAGEBAR_HEIGHT);

	self.mainPagebar = [[ReaderMainPagebar alloc] initWithFrame:pagebarRect document:self.document]; // At bottom

	self.mainPagebar.delegate = self;

	[self.view addSubview:self.mainPagebar];

	UITapGestureRecognizer *singleTapOne = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
	singleTapOne.numberOfTouchesRequired = 1; singleTapOne.numberOfTapsRequired = 1; singleTapOne.delegate = self;

	UITapGestureRecognizer *doubleTapOne = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
	doubleTapOne.numberOfTouchesRequired = 1; doubleTapOne.numberOfTapsRequired = 2; doubleTapOne.delegate = self;

	UITapGestureRecognizer *doubleTapTwo = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
	doubleTapTwo.numberOfTouchesRequired = 2; doubleTapTwo.numberOfTapsRequired = 2; doubleTapTwo.delegate = self;

	[singleTapOne requireGestureRecognizerToFail:doubleTapOne]; // Single tap requires double tap to fail

	[self.view addGestureRecognizer:singleTapOne];
	[self.view addGestureRecognizer:doubleTapOne];
	[self.view addGestureRecognizer:doubleTapTwo];

	self.contentViews = [NSMutableDictionary dictionary]; self.lastHideTime = [NSDate date];
}

- (void)viewWillAppear:(BOOL)animated
{
#ifdef DEBUGX
	NSLog(@"%s %@", __FUNCTION__, NSStringFromCGRect(self.view.bounds));
#endif

	[super viewWillAppear:animated];

	if (CGSizeEqualToSize(lastAppearSize, CGSizeZero) == false)
	{
		if (CGSizeEqualToSize(lastAppearSize, self.view.bounds.size) == false)
		{
			[self updateScrollViewContentViews]; // Update content views
		}

		lastAppearSize = CGSizeZero; // Reset view size tracking
	}
}

- (void)viewDidAppear:(BOOL)animated
{
#ifdef DEBUGX
	NSLog(@"%s %@", __FUNCTION__, NSStringFromCGRect(self.view.bounds));
#endif

	[super viewDidAppear:animated];

	if (CGSizeEqualToSize(self.theScrollView.contentSize, CGSizeZero)) // First time
	{
		[self performSelector:@selector(showDocument:) withObject:nil afterDelay:0.02];
	}

#if (READER_DISABLE_IDLE == TRUE) // Option

	[UIApplication sharedApplication].idleTimerDisabled = YES;

#endif // end of READER_DISABLE_IDLE Option
}

- (void)viewWillDisappear:(BOOL)animated
{
#ifdef DEBUGX
	NSLog(@"%s %@", __FUNCTION__, NSStringFromCGRect(self.view.bounds));
#endif

	[super viewWillDisappear:animated];

	lastAppearSize = self.view.bounds.size; // Track view size

#if (READER_DISABLE_IDLE == TRUE) // Option

	[UIApplication sharedApplication].idleTimerDisabled = NO;

#endif // end of READER_DISABLE_IDLE Option
}

- (void)viewDidDisappear:(BOOL)animated
{
#ifdef DEBUGX
	NSLog(@"%s %@", __FUNCTION__, NSStringFromCGRect(self.view.bounds));
#endif

	[super viewDidDisappear:animated];
}

- (void)viewDidUnload
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

    self.lastHideTime = nil; lastAppearSize = CGSizeZero; currentPage = 0;

	[super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
#ifdef DEBUGX
	NSLog(@"%s (%d)", __FUNCTION__, interfaceOrientation);
#endif

	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
#ifdef DEBUGX
	NSLog(@"%s %@ (%d)", __FUNCTION__, NSStringFromCGRect(self.view.bounds), toInterfaceOrientation);
#endif

	if (isVisible == NO) return; // iOS present modal bodge

	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
	{
		if (self.printInteraction != nil) [self.printInteraction dismissAnimated:NO];
	}
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
#ifdef DEBUGX
	NSLog(@"%s %@ (%d)", __FUNCTION__, NSStringFromCGRect(self.view.bounds), interfaceOrientation);
#endif

	if (isVisible == NO) return; // iOS present modal bodge

	[self updateScrollViewContentViews]; // Update content views

	lastAppearSize = CGSizeZero; // Reset view size tracking
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
#ifdef DEBUGX
	NSLog(@"%s %@ (%d to %d)", __FUNCTION__, NSStringFromCGRect(self.view.bounds), fromInterfaceOrientation, self.interfaceOrientation);
#endif

	//if (isVisible == NO) return; // iOS present modal bodge

	//if (fromInterfaceOrientation == self.interfaceOrientation) return;
}

- (void)didReceiveMemoryWarning
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[super didReceiveMemoryWarning];
}

#pragma mark UIScrollViewDelegate methods

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	__block NSInteger page = 0;

	CGFloat contentOffsetX = scrollView.contentOffset.x;

	[self.contentViews enumerateKeysAndObjectsUsingBlock: // Enumerate content views
		^(id key, id object, BOOL *stop)
		{
			ReaderContentView *contentView = object;

			if (contentView.frame.origin.x == contentOffsetX)
			{
				page = contentView.tag; *stop = YES;
			}
		}
	];

	if (page != 0) [self showDocumentPage:page]; // Show the page
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[self showDocumentPage:self.theScrollView.tag]; // Show page

	self.theScrollView.tag = 0; // Clear page number tag
}

#pragma mark UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)recognizer shouldReceiveTouch:(UITouch *)touch
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if ([touch.view isKindOfClass:[UIScrollView class]]) return YES;

	return NO;
}

#pragma mark UIGestureRecognizer action methods

- (void)decrementPageNumber
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (self.theScrollView.tag == 0) // Scroll view did end
	{
		NSInteger page = [self.document.pageNumber integerValue];
		NSInteger maxPage = [self.document.pageCount integerValue];
		NSInteger minPage = 1; // Minimum

		if ((maxPage > minPage) && (page != minPage))
		{
			CGPoint contentOffset = self.theScrollView.contentOffset;

			contentOffset.x -= self.theScrollView.bounds.size.width; // -= 1

			[self.theScrollView setContentOffset:contentOffset animated:YES];

			self.theScrollView.tag = (page - 1); // Decrement page number
		}
	}
}

- (void)incrementPageNumber
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (self.theScrollView.tag == 0) // Scroll view did end
	{
		NSInteger page = [self.document.pageNumber integerValue];
		NSInteger maxPage = [self.document.pageCount integerValue];
		NSInteger minPage = 1; // Minimum

		if ((maxPage > minPage) && (page != maxPage))
		{
			CGPoint contentOffset = self.theScrollView.contentOffset;

			contentOffset.x += self.theScrollView.bounds.size.width; // += 1

			[self.theScrollView setContentOffset:contentOffset animated:YES];

			self.theScrollView.tag = (page + 1); // Increment page number
		}
	}
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (recognizer.state == UIGestureRecognizerStateRecognized)
	{
		CGRect viewRect = recognizer.view.bounds; // View bounds

		CGPoint point = [recognizer locationInView:recognizer.view];

		CGRect areaRect = CGRectInset(viewRect, TAP_AREA_SIZE, 0.0f); // Area

		if (CGRectContainsPoint(areaRect, point)) // Single tap is inside the area
		{
			NSInteger page = [self.document.pageNumber integerValue]; // Current page #

			NSNumber *key = [NSNumber numberWithInteger:page]; // Page number key

			ReaderContentView *targetView = [self.contentViews objectForKey:key];

			id target = [targetView singleTap:recognizer]; // Process tap

			if (target != nil) // Handle the returned target object
			{
				if ([target isKindOfClass:[NSURL class]]) // Open a URL
				{
					NSURL *url = (NSURL *)target; // Cast to a NSURL object

					if (url.scheme == nil) // Handle a missing URL scheme
					{
						NSString *www = url.absoluteString; // Get URL string

						if ([www hasPrefix:@"www"] == YES) // Check for 'www' prefix
						{
							NSString *http = [NSString stringWithFormat:@"http://%@", www];

							url = [NSURL URLWithString:http]; // Proper http-based URL
						}
					}

					if ([[UIApplication sharedApplication] openURL:url] == NO)
					{
						#ifdef DEBUG
							NSLog(@"%s '%@'", __FUNCTION__, url); // Bad or unknown URL
						#endif
					}
				}
				else // Not a URL, so check for other possible object type
				{
					if ([target isKindOfClass:[NSNumber class]]) // Goto page
					{
						NSInteger value = [target integerValue]; // Number

						[self showDocumentPage:value]; // Show the page
					}
				}
			}
			else // Nothing active tapped in the target content view
			{
				if ([self.lastHideTime timeIntervalSinceNow] < -0.75) // Delay since hide
				{
					if ((self.mainToolbar.hidden == YES) || (self.mainPagebar.hidden == YES))
					{
						[self.mainToolbar showToolbar]; [self.mainPagebar showPagebar]; // Show
					}
				}
			}

			return;
		}

		CGRect nextPageRect = viewRect;
		nextPageRect.size.width = TAP_AREA_SIZE;
		nextPageRect.origin.x = (viewRect.size.width - TAP_AREA_SIZE);

		if (CGRectContainsPoint(nextPageRect, point)) // page++ area
		{
			[self incrementPageNumber]; return;
		}

		CGRect prevPageRect = viewRect;
		prevPageRect.size.width = TAP_AREA_SIZE;

		if (CGRectContainsPoint(prevPageRect, point)) // page-- area
		{
			[self decrementPageNumber]; return;
		}
	}
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (recognizer.state == UIGestureRecognizerStateRecognized)
	{
		CGRect viewRect = recognizer.view.bounds; // View bounds

		CGPoint point = [recognizer locationInView:recognizer.view];

		CGRect zoomArea = CGRectInset(viewRect, TAP_AREA_SIZE, TAP_AREA_SIZE);

		if (CGRectContainsPoint(zoomArea, point)) // Double tap is in the zoom area
		{
			NSInteger page = [self.document.pageNumber integerValue]; // Current page #

			NSNumber *key = [NSNumber numberWithInteger:page]; // Page number key

			ReaderContentView *targetView = [self.contentViews objectForKey:key];

			switch (recognizer.numberOfTouchesRequired) // Touches count
			{
				case 1: // One finger double tap: zoom ++
				{
					[targetView zoomIncrement]; break;
				}

				case 2: // Two finger double tap: zoom --
				{
					[targetView zoomDecrement]; break;
				}
			}

			return;
		}

		CGRect nextPageRect = viewRect;
		nextPageRect.size.width = TAP_AREA_SIZE;
		nextPageRect.origin.x = (viewRect.size.width - TAP_AREA_SIZE);

		if (CGRectContainsPoint(nextPageRect, point)) // page++ area
		{
			[self incrementPageNumber]; return;
		}

		CGRect prevPageRect = viewRect;
		prevPageRect.size.width = TAP_AREA_SIZE;

		if (CGRectContainsPoint(prevPageRect, point)) // page-- area
		{
			[self decrementPageNumber]; return;
		}
	}
}

#pragma mark ReaderContentViewDelegate methods

- (void)contentView:(ReaderContentView *)contentView touchesBegan:(NSSet *)touches
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if ((self.mainToolbar.hidden == NO) || (self.mainPagebar.hidden == NO))
	{
		if (touches.count == 1) // Single touches only
		{
			UITouch *touch = [touches anyObject]; // Touch info

			CGPoint point = [touch locationInView:self.view]; // Touch location

			CGRect areaRect = CGRectInset(self.view.bounds, TAP_AREA_SIZE, TAP_AREA_SIZE);

			if (CGRectContainsPoint(areaRect, point) == false) return;
		}

		[self.mainToolbar hideToolbar]; [self.mainPagebar hidePagebar]; // Hide

        self.lastHideTime = [NSDate new];
	}
}

#pragma mark ReaderMainToolbarDelegate methods

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar doneButton:(UIButton *)button
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

#if (READER_STANDALONE == FALSE) // Option

	[self.document saveReaderDocument]; // Save any ReaderDocument object changes

	[[ReaderThumbQueue sharedInstance] cancelOperationsWithGUID:self.document.guid];

	[[ReaderThumbCache sharedInstance] removeAllObjects]; // Empty the thumb cache

	if (self.printInteraction != nil) [self.printInteraction dismissAnimated:NO]; // Dismiss

	if ([delegate respondsToSelector:@selector(dismissReaderViewController:)] == YES)
	{
		[delegate dismissReaderViewController:self]; // Dismiss the ReaderViewController
	}
	else // We have a "Delegate must respond to -dismissReaderViewController: error"
	{
		NSAssert(NO, @"Delegate must respond to -dismissReaderViewController:");
	}

#endif // end of READER_STANDALONE Option
}

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar thumbsButton:(UIButton *)button
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (self.printInteraction != nil) [self.printInteraction dismissAnimated:NO]; // Dismiss

	ThumbsViewController *thumbsViewController = [[ThumbsViewController alloc] initWithReaderDocument:self.document];

	thumbsViewController.delegate = self; thumbsViewController.title = self.title;

	thumbsViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	thumbsViewController.modalPresentationStyle = UIModalPresentationFullScreen;

    [self presentViewController:thumbsViewController animated:YES completion:NULL];

}

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar printButton:(UIButton *)button
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

#if (READER_ENABLE_PRINT == TRUE) // Option

	Class printInteractionController = NSClassFromString(@"UIPrintInteractionController");

	if ((printInteractionController != nil) && [printInteractionController isPrintingAvailable])
	{
		NSURL *fileURL = self.document.fileURL; // Document file URL

		self.printInteraction = [printInteractionController sharedPrintController];

		if ([printInteractionController canPrintURL:fileURL] == YES) // Check first
		{
			UIPrintInfo *printInfo = [NSClassFromString(@"UIPrintInfo") printInfo];

			printInfo.duplex = UIPrintInfoDuplexLongEdge;
			printInfo.outputType = UIPrintInfoOutputGeneral;
			printInfo.jobName = self.document.fileName;

			self.printInteraction.printInfo = printInfo;
			self.printInteraction.printingItem = fileURL;
			self.printInteraction.showsPageRange = YES;

			if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
			{
				[self.printInteraction presentFromRect:button.bounds inView:button animated:YES completionHandler:
					^(UIPrintInteractionController *pic, BOOL completed, NSError *error)
					{
						#ifdef DEBUG
							if ((completed == NO) && (error != nil)) NSLog(@"%s %@", __FUNCTION__, error);
						#endif
					}
				];
			}
			else // Presume UIUserInterfaceIdiomPhone
			{
				[self.printInteraction presentAnimated:YES completionHandler:
					^(UIPrintInteractionController *pic, BOOL completed, NSError *error)
					{
						#ifdef DEBUG
							if ((completed == NO) && (error != nil)) NSLog(@"%s %@", __FUNCTION__, error);
						#endif
					}
				];
			}
		}
	}

#endif // end of READER_ENABLE_PRINT Option
}

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar emailButton:(UIButton *)button
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

#if (READER_ENABLE_MAIL == TRUE) // Option

	if ([MFMailComposeViewController canSendMail] == NO) return;

	if (self.printInteraction != nil) [self.printInteraction dismissAnimated:YES];

	unsigned long long fileSize = [self.document.fileSize unsignedLongLongValue];

	if (fileSize < (unsigned long long)15728640) // Check attachment size limit (15MB)
	{
		NSURL *fileURL = self.document.fileURL; NSString *fileName = self.document.fileName; // Document

		NSData *attachment = [NSData dataWithContentsOfURL:fileURL options:(NSDataReadingMapped|NSDataReadingUncached) error:nil];

		if (attachment != nil) // Ensure that we have valid document file attachment data
		{
			MFMailComposeViewController *mailComposer = [MFMailComposeViewController new];

			[mailComposer addAttachmentData:attachment mimeType:@"application/pdf" fileName:fileName];

			[mailComposer setSubject:fileName]; // Use the document file name for the subject

			mailComposer.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
			mailComposer.modalPresentationStyle = UIModalPresentationFormSheet;

			mailComposer.mailComposeDelegate = self; // Set the delegate

            [self presentViewController:mailComposer animated:YES completion:NULL];
		}
	}

#endif // end of READER_ENABLE_MAIL Option
}

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar markButton:(UIButton *)button
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (self.printInteraction != nil) [self.printInteraction dismissAnimated:YES];

	NSInteger page = [self.document.pageNumber integerValue];

	if ([self.document.bookmarks containsIndex:page])
	{
		[self.mainToolbar setBookmarkState:NO];

		[self.document.bookmarks removeIndex:page];
	}
	else // Add the bookmarked page index
	{
		[self.mainToolbar setBookmarkState:YES];

		[self.document.bookmarks addIndex:page];
	}
}

#pragma mark MFMailComposeViewControllerDelegate methods

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	#ifdef DEBUG
		if ((result == MFMailComposeResultFailed) && (error != NULL)) NSLog(@"%@", error);
	#endif

    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark ThumbsViewControllerDelegate methods

- (void)dismissThumbsViewController:(ThumbsViewController *)viewController
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[self updateToolbarBookmarkIcon]; // Update bookmark icon

    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)thumbsViewController:(ThumbsViewController *)viewController gotoPage:(NSInteger)page
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[self showDocumentPage:page]; // Show the page
}

#pragma mark ReaderMainPagebarDelegate methods

- (void)pagebar:(ReaderMainPagebar *)pagebar gotoPage:(NSInteger)page
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[self showDocumentPage:page]; // Show the page
}

#pragma mark UIApplication notification methods

- (void)applicationWill:(NSNotification *)notification
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[self.document saveReaderDocument]; // Save any ReaderDocument object changes

	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
	{
		if (self.printInteraction != nil) [self.printInteraction dismissAnimated:NO];
	}
}

@end
