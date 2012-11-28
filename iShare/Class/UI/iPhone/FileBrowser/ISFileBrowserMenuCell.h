//
//  ISFileBrowserMenuCell.h
//  iShare
//
//  Created by Jin Jin on 12-8-5.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ISFileBrowserCellInterface.h"

@class FileBrowserDataSource;

@interface ISFileBrowserMenuCell : UITableViewCell<ISFileBrowserCellInterface, UIAlertViewDelegate>

@property (nonatomic, strong) IBOutlet UIView* containerView;

@property (nonatomic, strong) IBOutlet UIButton* deleteButton;
@property (nonatomic, strong) IBOutlet UIButton* openButton;
@property (nonatomic, strong) IBOutlet UIButton* mailButton;
@property (nonatomic, strong) IBOutlet UIButton* zipButton;
@property (nonatomic, strong) IBOutlet UIButton* renameButton;

@property (nonatomic, weak) FileBrowserDataSource* dataSource;

-(IBAction)deleteButtonClicked:(id)sender;
-(IBAction)openButtonClicked:(id)sender;
-(IBAction)mailButtonClicked:(id)sender;
-(IBAction)renameButtonClicked:(id)sender;
-(IBAction)zipButtonClicked:(id)sender;

@end
