//
//  ISWifiViewController.h
//  iShare
//
//  Created by Jin Jin on 12-9-10.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ISWifiViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet UITableView* tableView;

@property (nonatomic, strong) IBOutlet UITableViewCell* enableCell;
@property (nonatomic, strong) IBOutlet UITableViewCell* portCell;
@property (nonatomic, strong) IBOutlet UITableViewCell* authEnableCell;
@property (nonatomic, strong) IBOutlet UITableViewCell* authUsernameCell;
@property (nonatomic, strong) IBOutlet UITableViewCell* authPasswordCell;

@property (nonatomic, strong) IBOutlet UISwitch* httpEnableSwitch;
@property (nonatomic, strong) IBOutlet UISwitch* authEnableSwitch;

-(IBAction)httpEnableSwitchValueChanged:(id)sender;
-(IBAction)authEnableSwitchValueChanged:(id)sender;

@end
