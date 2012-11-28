//
//  ISPasscodeProtectionController.h
//  iShare
//
//  Created by Jin Jin on 12-11-3.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PAPasscodeViewController.h"

@interface ISPasscodeProtectionController : UIViewController<PAPasscodeViewControllerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) IBOutlet UITableView* tableView;

@end
