//
//  ISFileQuickPreviewController.m
//  iShare
//
//  Created by Jin Jin on 12-8-12.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISFileQuickPreviewController.h"

@interface ISFileQuickPreviewController ()

@property (nonatomic, strong) NSArray* previewItems;

@end

@implementation ISFileQuickPreviewController

-(id)initWithPreviewItems:(NSArray*)items{
    self = [super init];
    
    if (self){
        self.previewItems = items;
        self.dataSource = self;
        self.delegate = self;
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
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - quick preview data source
-(NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller{
    return [self.previewItems count];
}

-(id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index{
    return [self.previewItems objectAtIndex:index];
}

@end
