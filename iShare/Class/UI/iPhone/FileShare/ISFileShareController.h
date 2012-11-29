//
//  ISFileShareController.h
//  iShare
//
//  Created by Jin Jin on 12-8-3.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ISFileShareController : UIViewController<UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) IBOutlet UITableView* tableView;

@property (nonatomic, strong) IBOutlet UIButton* unlinkButton;
@property (nonatomic, strong) IBOutlet UIButton* gdUnlinkButton;

-(IBAction)unlinkDropbox:(id)sender;
-(IBAction)unlinkGoogleDrive:(id)sender;

@end
