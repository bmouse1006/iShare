//
//  ISBluetoothViewController.h
//  iShare
//
//  Created by Jin Jin on 12-9-5.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>
#import "JJBTFileSharer.h"
#import "AGImagePickerController.h"
#import "FilePickerViewController.h"

@interface ISBluetoothViewController : UIViewController <GKPeerPickerControllerDelegate, JJBTFileSharerDelegate, AGImagePickerControllerDelegate, FilePickerViewControllerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UIBarButtonItem* disconnectButton;
@property (nonatomic, strong) IBOutlet UIButton* showImagePickerButton;
@property (nonatomic, strong) IBOutlet UIButton* showFilePickerButton;
@property (nonatomic, strong) IBOutlet UILabel* titleLabel;

@property (nonatomic, strong) IBOutlet UITableView* sendingFilesTableView;
@property (nonatomic, strong) IBOutlet UITableView* receivingFilesTableView;

-(IBAction)disconnectButtonClicked:(id)sender;
-(IBAction)showImagePickerButtonClicked:(id)sender;
-(IBAction)showFilePickerButtonClicked:(id)sender;

@end
