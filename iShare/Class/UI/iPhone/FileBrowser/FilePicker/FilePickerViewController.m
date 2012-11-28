//
//  FilePickerViewController.m
//  iShare
//
//  Created by Jin Jin on 12-8-5.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "FilePickerViewController.h"
#import "FilePickerContentController.h"
#import "FileBrowserNotifications.h"
#import "FilePickerDataSource.h"
#import "FileOperationWrap.h"
#import "FileItem.h"

@interface FilePickerViewController ()

@property (nonatomic, copy) NSString* filePath;
@property (nonatomic, assign) FileContentType filterType;
@property (nonatomic, strong) UINavigationController* contentNavigation;

@end

@implementation FilePickerViewController

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(id)initWithFilePath:(NSString*)filePath filterType:(FileContentType)type;{
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self){
        self.filePath = filePath;
        self.filterType = type;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doneActionReceived:) name:NOTIFICATION_PICKERCONTENT_DONE object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelActionReceived:) name:NOTIFICATION_PICKERCONTENT_CANCEL object:nil];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    FilePickerContentController* content = [[FilePickerContentController alloc] initWithFilePath:self.filePath filterType:self.filterType];
    self.contentNavigation = [[UINavigationController alloc] initWithRootViewController:content];
    self.contentNavigation.delegate = self;
    [self.pathScroll addSubview:self.pathLabel];
    [self.view addSubview:self.contentNavigation.view];
    [self.view addSubview:self.pathScroll];
    
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.contentNavigation = nil;
    self.pathScroll = nil;
    self.pathLabel = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    self.contentNavigation.view.frame = self.view.bounds;
    CGRect frame = self.pathScroll.frame;
    frame.origin.x = 0;
    frame.origin.y = self.view.frame.size.height - frame.size.height;
    self.pathScroll.frame = frame;
}

#pragma mark - getter and setter
-(NSString*)currentDirectory{
    FilePickerContentController* contentController = (FilePickerContentController*)[self.contentNavigation topViewController];
    return contentController.filePath;
}

-(NSArray*)selectedFiles{
    FilePickerContentController* contentController = (FilePickerContentController*)[self.contentNavigation topViewController];
    return contentController.selectedFilePath;
}

#pragma mark - notification
-(void)doneActionReceived:(NSNotification*)notification{
    NSArray* pathArray = nil;
    if (self.filterType == FileContentTypeDirectory){
        pathArray = @[[self currentDirectory]];
    }else{
        pathArray = [self selectedFiles];
    }
    
    if (self.completionBlock){
        self.completionBlock(pathArray);
    }
    
    if ([self.delegate respondsToSelector:@selector(filePicker:finishedWithPickedPaths:)]){
        [self.delegate filePicker:self finishedWithPickedPaths:pathArray];
    }
}

-(void)cancelActionReceived:(NSNotification*)notification{
    
    if (self.cancellationBlock){
        self.cancellationBlock();
    }
    
    if ([self.delegate respondsToSelector:@selector(filePickerCancelled:)]){
        [self.delegate filePickerCancelled:self];
    }
}

#pragma mark - navigation controller delegate
-(void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    NSMutableString* workingPath = [NSMutableString stringWithString:[self currentDirectory]];
    NSRange range = {0, [workingPath length]};
    [workingPath replaceOccurrencesOfString:[FileOperationWrap homePath] withString:@"" options:NSLiteralSearch range:range];
    if (workingPath.length == 0){
        [workingPath appendString:@"/"];
    }
    self.pathLabel.text = workingPath;
    [self.pathLabel sizeToFit];
    self.pathScroll.contentSize = self.pathLabel.frame.size;
    self.pathScroll.contentOffset = CGPointMake((self.pathLabel.frame.size.width - self.pathScroll.frame.size.width)/2, (self.pathLabel.frame.size.height - self.pathScroll.frame.size.height)/2);
}

@end
