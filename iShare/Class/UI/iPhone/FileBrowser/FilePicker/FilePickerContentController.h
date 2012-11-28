//
//  FilePickerContentController.h
//  iShare
//
//  Created by Jin Jin on 12-8-12.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FilePickerDataSource.h"
#import "FilePickerViewController.h"
#import "FileOperationWrap.h"

#define NOTIFICATION_PICKERCONTENT_CANCEL @"NOTIFICATION_PICKERCONTENT_CANCEL"
#define NOTIFICATION_PICKERCONTENT_DONE @"NOTIFICATION_PICKERCONTENT_DONE"

@interface FilePickerContentController : UITableViewController

@property (nonatomic, copy) NSString* filePath;
@property (nonatomic, readonly) NSArray* selectedFilePath;

-(id)initWithFilePath:(NSString*)filePath filterType:(FileContentType)type;

@property (nonatomic, strong) IBOutlet UIBarButtonItem* doneButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* cancelButton;
@property (nonatomic, assign) FileContentType filterType;

-(IBAction)doneButtonClicked:(id)sender;
-(IBAction)cancelButtonClicked:(id)sender;

@end
