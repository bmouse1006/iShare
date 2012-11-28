//
//  FilePickerViewController.h
//  iShare
//
//  Created by Jin Jin on 12-8-5.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FilePickerDataSource.h"
#import "FileOperationWrap.h"

typedef void(^FilePickerCompletionBlock)(NSArray*);
typedef void(^FilePickerCancellationBlock)(void);

@class FilePickerViewController;

@protocol FilePickerViewControllerDelegate <NSObject>

@optional
-(void)filePickerCancelled:(FilePickerViewController*)filePicker;
-(void)filePicker:(FilePickerViewController*)filePicker finishedWithPickedPaths:(NSArray*)pickedPaths;

@end

@interface FilePickerViewController : UIViewController<UITableViewDelegate, UINavigationControllerDelegate>

-(id)initWithFilePath:(NSString*)filePath filterType:(FileContentType)type;

@property (nonatomic, strong) IBOutlet UIScrollView* pathScroll;
@property (nonatomic, strong) IBOutlet UILabel* pathLabel;

@property (nonatomic, copy) FilePickerCompletionBlock completionBlock;
@property (nonatomic, copy) FilePickerCancellationBlock cancellationBlock;

@property (nonatomic, readonly) NSString* currentDirectory;
@property (nonatomic, weak) id<FilePickerViewControllerDelegate> delegate;


@end
