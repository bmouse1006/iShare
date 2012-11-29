//
//  ISNeighbourViewController.h
//  iShare
//
//  Created by Jin Jin on 12-11-28.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ISNeighbourViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, NSNetServiceBrowserDelegate>

@property (nonatomic, strong) IBOutlet UITableView* tableView;

@end
