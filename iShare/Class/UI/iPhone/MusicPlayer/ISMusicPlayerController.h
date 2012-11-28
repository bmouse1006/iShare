//
//  ISMusicPlayerController.h
//  iShare
//
//  Created by Jin Jin on 12-8-3.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ISMusicPlayerController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UIButton* nowPlayingButton;
@property (nonatomic, strong) IBOutlet UITableView* tableView;
@property (nonatomic, strong) IBOutlet UITableViewCell* addSongCell;
@property (nonatomic, strong) IBOutlet UILabel* addSongCellLabel;

-(IBAction)nowPlayingButtonIsClicked:(id)sender;

@end
