//
//  ISBluetoothViewController.m
//  iShare
//
//  Created by Jin Jin on 12-9-5.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISBluetoothViewController.h"
#import "ISBTSendingCell.h"
#import "ISBTReceivingCell.h"
#import "SVProgressHUD.h"

@interface ISBluetoothViewController ()

@property (nonatomic, strong) GKSession* gkSession;

@property (nonatomic, strong) UIBarButtonItem* previousBackButton;
@property (nonatomic, strong) NSMutableArray* receivingFileItems;
@property (nonatomic, strong) NSMutableArray* fileSenders;
@property (nonatomic, assign) BTSenderType receivingType;

@end

@implementation ISBluetoothViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)dealloc{
    JJBTFileSharer* btSharer = [JJBTFileSharer defaultSharer];
    btSharer.delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"cell_title_bluetooth", nil);
    
    
    JJBTFileSharer* btSharer = [JJBTFileSharer defaultSharer];
    btSharer.delegate = self;
    
    //view background color
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_texture"]];
    
    [self.disconnectButton setTitle:NSLocalizedString(@"btn_title_disconnect", nil)];
    [self.disconnectButton setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [self.disconnectButton setTintColor:[UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1]];
    
    UIEdgeInsets insets = UIEdgeInsetsMake(7, 7, 7, 7);
    
    UIImage* btnBackground = [[UIImage imageNamed:@"compose-add-button-background"] resizableImageWithCapInsets:insets];
    UIImage* btnBackgroundPressed = [[UIImage imageNamed:@"compose-add-button-background-pressed"] resizableImageWithCapInsets:insets];
    
    [self.showFilePickerButton setBackgroundImage:btnBackground forState:UIControlStateNormal];
    [self.showFilePickerButton setBackgroundImage:btnBackgroundPressed forState:UIControlStateHighlighted];
    [self.showImagePickerButton setBackgroundImage:btnBackground forState:UIControlStateNormal];
    [self.showImagePickerButton setBackgroundImage:btnBackgroundPressed forState:UIControlStateHighlighted];
    
    [self.showImagePickerButton setTitle:NSLocalizedString(@"btn_title_showimagepicker", nil) forState:UIControlStateNormal];
    [self.showFilePickerButton setTitle:NSLocalizedString(@"btn_title_showfilepicker", nil) forState:UIControlStateNormal];
    
    self.titleLabel.text = NSLocalizedString(@"label_title_choosecontent", nil);
    
    if ([btSharer isConnected] == NO){
        GKPeerPickerController* picker = [[GKPeerPickerController alloc] init];
        picker.connectionTypesMask = GKPeerPickerConnectionTypeNearby;
        picker.delegate = self;
        [picker show];
        [self changeUIToStates:GKPeerStateDisconnected];
    }else{
        [self changeUIToStates:GKPeerStateConnected];
        switch ([btSharer status]) {
            case JJBTFileSharerStatusReceiving:
                //show receiving ui
                [self showReceivingUI];
                break;
            case JJBTFileSharerStatusSending:
                //show sending ui
                [self showSendingUI];
                break;
            default:
                break;
        }
    }
    
    self.fileSenders = [NSMutableArray arrayWithArray:[[JJBTFileSharer defaultSharer] allSenders]];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}

-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    self.sendingFilesTableView.frame = self.view.bounds;
    self.receivingFilesTableView.frame = self.view.bounds;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)changeUIToStates:(GKPeerConnectionState)state{
    switch (state) {
        case GKPeerStateConnected:
            [self.navigationItem setRightBarButtonItem:self.disconnectButton animated:YES];
//            self.title
            self.navigationItem.prompt = [NSString stringWithFormat:NSLocalizedString(@"nav_title_connectedwith", nil), [[JJBTFileSharer defaultSharer] nameOfPair]];
            break;
        default:
            self.navigationItem.prompt = nil;
            //not connected
            break;
    }
}

#pragma mark - action
-(IBAction)disconnectButtonClicked:(id)sender{
    [[JJBTFileSharer defaultSharer] endSession];
}

-(IBAction)showImagePickerButtonClicked:(id)sender{
    AGImagePickerController* imagePicker = [[AGImagePickerController alloc] initWithDelegate:self];
    [self presentModalViewController:imagePicker animated:YES];
}

-(IBAction)showFilePickerButtonClicked:(id)sender{
    FilePickerViewController* filePicker = [[FilePickerViewController alloc] initWithFilePath:nil filterType:FileContentTypeAll];
    filePicker.delegate = self;
    [self presentViewController:filePicker animated:YES completion:NULL];
}

#pragma mark - UI change
-(void)showSendingUI{
    [self.sendingFilesTableView removeFromSuperview];
    self.sendingFilesTableView = [self generateSendingTableView];
    [self.view addSubview:self.sendingFilesTableView];
    self.sendingFilesTableView.frame = self.view.bounds;
    [self.sendingFilesTableView reloadData];
}

-(void)showReceivingUI{
    [self.receivingFilesTableView removeFromSuperview];
    self.receivingFilesTableView = [self generateReceivingTableView];
    [self.view addSubview:self.receivingFilesTableView];
    self.receivingFilesTableView.frame = self.view.bounds;
    [self.receivingFilesTableView reloadData];
}

-(void)showOriginalUI{
    [self.sendingFilesTableView removeFromSuperview];
    self.sendingFilesTableView = nil;
    [self.receivingFilesTableView removeFromSuperview];
    self.receivingFilesTableView = nil;
}

-(void)showFinishedAlert:(BTSenderType)type{
    NSString* message = nil;
    if (type == BTSenderTypeFile){
        message = NSLocalizedString(@"alert_message_filereceivingfinished", nil);
    }else if (type == BTSenderTypePhoto){
        message = NSLocalizedString(@"alert_message_photoreceivingfinished", nil);
    }
    
    [SVProgressHUD showSuccessWithStatus:message duration:2.0f];
    
}
#pragma mark - GK session delegate

#pragma mark - GK peer picker delegate
-(void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session{
    self.gkSession = session;
    [JJBTFileSharer setDefaultGKSession:session];
    [picker dismiss];
    [self changeUIToStates:GKPeerStateConnected];
}

#pragma mark - bt file transfer delegate
//sending
-(void)sharerDidStartSending:(JJBTFileSharer *)sharer{
    //show sending view
    self.fileSenders = [NSMutableArray arrayWithArray:[[JJBTFileSharer defaultSharer] allSenders]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showSendingUI];
    });
}

-(void)sharerDidStartReceiving:(JJBTFileSharer *)sharer headContent:(NSMutableDictionary *)headContent{
    self.receivingFileItems = [headContent objectForKey:@"list"];
    self.receivingType = [[headContent objectForKey:@"type"] integerValue];
    NSString* version = [headContent objectForKey:@"version"];
    if ([version isEqualToString:CurrentVersion] == NO){
        return;
    }
    //type and version
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showReceivingUI];
    });
}

-(void)sharerDidEndSending:(JJBTFileSharer *)sharer{

    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"alert_message_sendingfinished", nil) duration:1.5f];
        [self showOriginalUI];
    });
}

-(void)sharerDidEndReceiving:(JJBTFileSharer *)sharer{
    self.receivingFileItems = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showFinishedAlert:self.receivingType];
        [self showOriginalUI];
    });
}

-(void)sharer:(JJBTFileSharer*)sharer willStartSendingWithIdentifier:(NSString *)identifier{
    
}

-(void)sharer:(JJBTFileSharer *)sharer didSendBytes:(long long)bytes identifier:(NSString *)identifier{
    //update sending cell here
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self sendingCellWithIdentifier:identifier] updateCell];
    });
}

-(void)sharer:(JJBTFileSharer*)sharer finishedSendingWithIdentifier:(NSString *)identifier{
    __block id object = nil;
    [self.fileSenders enumerateObjectsUsingBlock:^(JJBTSender* sender, NSUInteger idx, BOOL* stop){
        if ([[sender identifier] isEqualToString:identifier]){
            object = sender;
            *stop = YES;
        }
    }];
    
    if (object){
        [self.fileSenders removeObject:object];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSIndexPath* indexPath = [self.sendingFilesTableView indexPathForCell:[self sendingCellWithIdentifier:identifier]];
        if (indexPath){
            [self.sendingFilesTableView beginUpdates];
            [self.sendingFilesTableView deleteRowsAtIndexPaths:@[indexPath]
                                              withRowAnimation:UITableViewRowAnimationLeft];
            [self.sendingFilesTableView endUpdates];
        }else{
            [self.sendingFilesTableView reloadData];
        }
    });
}

-(void)sharer:(JJBTFileSharer*)sharer willStartReceivingWithIdentifier:(NSString *)identifier{
    
}
-(void)sharer:(JJBTFileSharer *)sharer didReceiveBytes:(long long)bytes identifier:(NSString *)identifier{
    //update receiving cell
    [[self.receivingFilesTableView visibleCells] enumerateObjectsUsingBlock:^(ISBTReceivingCell* cell, NSUInteger idx, BOOL* stop){
        if ([cell.identifier isEqualToString:identifier]){
            [cell setReceivedBytes:bytes];
            *stop = YES;
        }
    }];
}


-(void)sharer:(JJBTFileSharer*)sharer finishedReceivingWithIdentifier:(NSString *)identifier{
    
    __block id object = nil;
    [self.receivingFileItems enumerateObjectsUsingBlock:^(NSDictionary* item, NSUInteger idx, BOOL* stop){
        if ([[item objectForKey:@"identifier"] isEqualToString:identifier]){
            object = item;
            *stop = YES;
        }
    }];
    
    if (object){
        [self.receivingFileItems removeObject:object];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSIndexPath* indexPath = [self.receivingFilesTableView indexPathForCell:[self receivingCellWithIdentifier:identifier]];
        if (indexPath){
            [self.receivingFilesTableView beginUpdates];
            [self.receivingFilesTableView deleteRowsAtIndexPaths:@[indexPath]
                                              withRowAnimation:UITableViewRowAnimationFade];
            [self.receivingFilesTableView endUpdates];
        }else{
            [self.receivingFilesTableView reloadData];
        }
    });
}

-(void)sharer:(JJBTFileSharer*)sharer currentTransitionFailed:(NSError*)error{
    
}
-(void)sharerTransitionCancelled:(JJBTFileSharer*)sharer{
    
}

-(void)sharerIsDisconnectedWithPair:(JJBTFileSharer*)sharer{
    [self changeUIToStates:GKPeerStateDisconnected];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(ISBTSendingCell*)sendingCellWithIdentifier:(NSString*)identifier{
    __block ISBTSendingCell* retCell = nil;
    [[self.sendingFilesTableView visibleCells] enumerateObjectsUsingBlock:^(ISBTSendingCell* cell, NSUInteger idx, BOOL* stop){
        if ([cell.identifier isEqualToString:identifier]){
            retCell = cell;
            *stop = YES;
        }
    }];
    
    return retCell;
}

-(ISBTReceivingCell*)receivingCellWithIdentifier:(NSString*)identifier{
    __block ISBTReceivingCell* retCell = nil;
    [[self.receivingFilesTableView visibleCells] enumerateObjectsUsingBlock:^(ISBTReceivingCell* cell, NSUInteger idx, BOOL* stop){
        if ([cell.identifier isEqualToString:identifier]){
            retCell = cell;
            *stop = YES;
        }
    }];
    
    return retCell;
}

#pragma mark - Image Picker delegate
-(void)agImagePickerController:(AGImagePickerController *)picker didFail:(NSError *)error{
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

-(void)agImagePickerController:(AGImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info{
    [[JJBTFileSharer defaultSharer] sendPhotos:info];
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - File Picker delegate
-(void)filePicker:(FilePickerViewController *)filePicker finishedWithPickedPaths:(NSArray *)pickedPaths{
    [[JJBTFileSharer defaultSharer] sendFiles:pickedPaths];
    [filePicker dismissViewControllerAnimated:YES completion:NULL];
}

-(void)filePickerCancelled:(FilePickerViewController *)filePicker{
    [filePicker dismissViewControllerAnimated:YES completion:NULL];    
}

#pragma mark - table view delegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
}

#pragma mark - table view datasource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (tableView == self.sendingFilesTableView){
        return [self.fileSenders count];
    }else if (tableView == self.receivingFilesTableView){
        return [self.receivingFileItems count];
    }
    
    return 0;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == self.sendingFilesTableView){
        static NSString* SendingCellIdentity = @"SendingCellIdentity";
        ISBTSendingCell* cell = [tableView dequeueReusableCellWithIdentifier:SendingCellIdentity];
        if (cell == nil){
            cell = [[[NSBundle mainBundle] loadNibNamed:@"ISBTSendingCell" owner:nil options:nil] objectAtIndex:0];
        }
        
        JJBTSender* sender = [self.fileSenders objectAtIndex:indexPath.row];
        
        [cell configCell:sender];
        
        return cell;
    }else{
        //receiving cell
        static NSString* ReceivingCellIdentity = @"ReceivingCellIdentity";
        ISBTReceivingCell* cell = [tableView dequeueReusableCellWithIdentifier:ReceivingCellIdentity];
        if (cell == nil){
            cell = [[[NSBundle mainBundle] loadNibNamed:@"ISBTReceivingCell" owner:nil options:nil] objectAtIndex:0];
        }
        
        [cell configCell:[self.receivingFileItems objectAtIndex:indexPath.row]];
        
        return cell;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50.0f;
}

#pragma mark - generating table view
-(UITableView*)generateSendingTableView{
    UITableView* tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    UILabel* sendingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 30)];
    sendingLabel.backgroundColor = [UIColor clearColor];
    sendingLabel.textAlignment = UITextAlignmentCenter;
    sendingLabel.font = [UIFont boldSystemFontOfSize:13];
    sendingLabel.textColor = [UIColor darkGrayColor];
    sendingLabel.shadowColor = [UIColor whiteColor];
    sendingLabel.shadowOffset = CGSizeMake(0, 1);
    sendingLabel.text = NSLocalizedString(@"label_title_sending", nil);
    tableView.tableHeaderView = sendingLabel;
    tableView.delegate = self;
    tableView.dataSource = self;
    return tableView;
}

-(UITableView*)generateReceivingTableView{
    UITableView* tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    UILabel* receivingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 30)];
    receivingLabel.backgroundColor = [UIColor clearColor];
    receivingLabel.textAlignment = UITextAlignmentCenter;
    receivingLabel.font = [UIFont boldSystemFontOfSize:13];
    receivingLabel.textColor = [UIColor darkGrayColor];
    receivingLabel.shadowColor = [UIColor whiteColor];
    receivingLabel.shadowOffset = CGSizeMake(0, 1);
    receivingLabel.text = NSLocalizedString(@"label_title_receiving", nil);
    tableView.tableHeaderView = receivingLabel;
    tableView.delegate = self;
    tableView.dataSource = self;
    return tableView;
}

@end
