//
//  ISShareServiceBaseController.m
//  iShare
//
//  Created by Jin Jin on 12-8-26.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISShareServiceBaseController.h"
#import "ISShareServiceTableViewCell.h"
#import "SVProgressHUD.h"

#define kNewFolderNameDirectory 999

@interface ISShareServiceBaseController (){
    BOOL _firstAppear;
}

@property (nonatomic, strong) NSIndexPath* selectedIndexPath;

@end

@implementation ISShareServiceBaseController

-(void)dealloc{
    [SVProgressHUD dismiss];
}

-(id)initWithWorkingPath:(NSString*)workingPath{
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self){
        self.workingPath = workingPath;
        _firstAppear = YES;
    }
    
    return self;
}

-(void)loadView{
    [super loadView];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    
    self.addDirectoryButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addDirectoryButtonClicked:)];
    self.uploadButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_upload"] style:UIBarButtonItemStylePlain target:self action:@selector(uploadButtonClicked:)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.navigationItem.rightBarButtonItems = @[self.addDirectoryButton, self.uploadButton];
    
    self.dataSource = [self createModel];
    self.dataSource.delegate = self;
    
    self.tableView.dataSource = self.dataSource;
    self.tableView.delegate = self;
    
    [self.view addSubview:self.tableView];
    
    //show waiting message
    if ([self serviceAutherized] == YES){
        [self startLoading];
    }
}

-(void)startLoading{
    [SVProgressHUD showWithStatus:NSLocalizedString(@"progress_message_loadingcontent", nil)];
    [self.dataSource startLoading];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.tableView = nil;
    self.dataSource = nil;
    self.addDirectoryButton = nil;
    self.uploadButton = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
//    if([self serviceAutherized] == NO){
//        if (_firstAppear){
//            [self autherizeService];
//        }
//    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];	
    
    if ([self serviceAutherized] == NO){
        if (_firstAppear == NO){
            [self autherizeFailed];
        }else{
            [self autherizeService];
            _firstAppear = NO;
        }
    }
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}

-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

#pragma mark - tableview delegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    FileShareServiceItem* item = [self.dataSource objectAtIndexPath:indexPath];
    if (item.isDirectory){
        [self.navigationController pushViewController:[self controllerForChildFolder:item.filePath] animated:YES];
    }else{
        //show menu
        self.selectedIndexPath = indexPath;
        [self showMenuInCell:[tableView cellForRowAtIndexPath:indexPath]];
    }
}

-(BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath{
    [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
    [self becomeFirstResponder];
    UIMenuItem* deleteItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"menu_title_delete", nil) action:@selector(deleteAction:)];
//    UIMenuItem* renameItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"menu_title_rename", nil) action:@selector(renameAction:)];
//    UIMenuItem* downloadItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"menu_title_download", nil) action:@selector(downloadAction:)];
    [[UIMenuController sharedMenuController] setMenuItems:@[deleteItem]];
    self.selectedIndexPath = indexPath;
    
    FileShareServiceItem* item = [self.dataSource objectAtIndexPath:indexPath];
    return item.isDirectory;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender{
    return action == @selector(delete:);
    
}
- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender{
    
}

#pragma mark - should override
-(BOOL)serviceAutherized{
    return YES;
}

-(void)autherizeService{
    
}

-(void)autherizeFailed{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(ISShareServiceBaseDataSource*)createModel{
    return nil;
}

-(void)createNewFolder:(NSString*)folderName{
    
}

-(UIViewController*)controllerForChildFolder:(NSString*)folderPath{
    id controller = [[[self class] alloc] initWithWorkingPath:folderPath];
    return controller;
}

-(void)deleteFileAtPath:(NSString *)filePath{
    
}

-(void)downloadFinished{
    [SVProgressHUD dismissWithSuccess:NSLocalizedString(@"progress_message_downloadfinished", nil) afterDelay:1];
}

-(void)downloadFailed:(NSError*)error{
    [SVProgressHUD dismissWithError:NSLocalizedString(@"progress_message_downloadfailed", nil) afterDelay:1];
}

-(void)uploadFinished{
    [SVProgressHUD dismissWithSuccess:NSLocalizedString(@"progress_message_uploadingfinished", nil) afterDelay:1];
    [self.dataSource loadContent];
}

-(void)uploadFailed:(NSError*)error{
    [SVProgressHUD dismissWithSuccess:NSLocalizedString(@"progress_message_uploadingfinished", nil) afterDelay:1];
}

-(void)deleteFinished{
    [self.dataSource removeObjectAtIndexPath:self.selectedIndexPath];
    [self.tableView deleteRowsAtIndexPaths:@[self.selectedIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
    self.selectedIndexPath = nil;
    [SVProgressHUD dismiss];
}

-(void)deleteFailed:(NSError *)error{
    NSLog(@"file delete failed: %@", [error localizedDescription]);
    [SVProgressHUD dismissWithError:NSLocalizedString(@"progress_message_actionfailed", nil)];
}

-(void)folderCreateFinished{
    [SVProgressHUD dismiss];
    [self startLoading];
}

-(void)folderCreateFailed:(NSError *)error{
    NSLog(@"folder create failed: %@", [error localizedDescription]);
    [SVProgressHUD dismissWithError:NSLocalizedString(@"progress_message_actionfailed", nil)];
}

#pragma mark - data source delegate
-(void)dataSourceDidFailLoading:(ISShareServiceBaseDataSource *)dataSource error:(NSError *)error{
    [SVProgressHUD dismiss];
    //show error happened
//    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"alert_title_error", nil) message:NSLocalizedString(@"alert_message_shareserviceerror", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"btn_title_cancel", nil) otherButtonTitles:nil];
//    [alert show];
}

-(void)dataSourceDidFinishLoading:(ISShareServiceBaseDataSource *)dataSource{
    //reload table view
    [SVProgressHUD dismiss];
    [self.tableView reloadData];
}

#pragma mark - button action
-(void)addDirectoryButtonClicked:(id)sender{
    UIAlertView* newFolderName = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"alert_title_inputdirectoryname", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"btn_title_cancel", nil) otherButtonTitles:NSLocalizedString(@"btn_title_confirm", nil), nil];
    newFolderName.alertViewStyle = UIAlertViewStylePlainTextInput;
    newFolderName.tag = kNewFolderNameDirectory;
    [newFolderName show];
}

-(void)uploadButtonClicked:(id)sender{
    FilePickerViewController* filePicker = [[FilePickerViewController alloc] initWithFilePath:nil filterType:FileContentTypeAll];
    filePicker.delegate = self;
    
    [self presentViewController:filePicker animated:YES completion:NULL];
}

#pragma mark - file picker delegate
-(void)filePickerCancelled:(FilePickerViewController *)filePicker{
    [filePicker dismissViewControllerAnimated:YES completion:NULL];
}

-(void)filePicker:(FilePickerViewController *)filePicker finishedWithPickedPaths:(NSArray *)pickedPaths{
    [SVProgressHUD showWithStatus:NSLocalizedString(@"progress_message_uploadingfiles", nil) maskType:SVProgressHUDMaskTypeClear];
    [filePicker dismissViewControllerAnimated:YES completion:NULL];
    [self uploadSelectedFiles:pickedPaths];
}

#pragma mark - alert view delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (alertView.tag) {
        case kNewFolderNameDirectory:
        {
            UITextField* nameField = [alertView textFieldAtIndex:0];
            if (buttonIndex == 1){
                //ok button
                [SVProgressHUD showWithStatus:NSLocalizedString(@"progress_message_creatingfolder", nil)];
                [self createNewFolder:nameField.text];
            }
        }
            break;
        default:
            break;
    }
}

#pragma mark - show menu
-(BOOL)canBecomeFirstResponder{
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return (action == @selector(deleteAction:) || action == @selector(downloadAction:));
}

- (void)showMenuInCell:(UITableViewCell*)cell{
    [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
    [self becomeFirstResponder];
    UIMenuItem* deleteItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"menu_title_delete", nil) action:@selector(deleteAction:)];
    UIMenuItem* downloadItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"menu_title_download", nil) action:@selector(downloadAction:)];
    [[UIMenuController sharedMenuController] setMenuItems:@[deleteItem, downloadItem]];
    [[UIMenuController sharedMenuController] update];
    [[UIMenuController sharedMenuController] setTargetRect:cell.bounds inView:cell];
    [[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
}

-(void)deleteAction:(id)sender{
    //delete remote files
    [SVProgressHUD showWithStatus:NSLocalizedString(@"progress_message_deleting", nil) maskType:SVProgressHUDMaskTypeClear];
    FileShareServiceItem* item = [self.dataSource objectAtIndexPath:self.selectedIndexPath];
    [self deleteFileAtPath:item.filePath];
}

-(void)renameAction:(id)sender{
    [SVProgressHUD showWithStatus:NSLocalizedString(@"progress_message_deleting", nil) maskType:SVProgressHUDMaskTypeClear];
}

-(void)downloadAction:(id)sender{
    //show file picker first
    FilePickerViewController* filePicker = [[FilePickerViewController alloc] initWithFilePath:nil filterType:FileContentTypeDirectory];
    self.selectedIndexPath = [self.tableView indexPathForSelectedRow];
    filePicker.completionBlock = ^(NSArray* selectedFolder){
        [SVProgressHUD showWithStatus:NSLocalizedString(@"progress_message_startdownloadingfile", nil) maskType:SVProgressHUDMaskTypeClear];
        //start download
        FileShareServiceItem* item = [self.dataSource objectAtIndexPath:self.selectedIndexPath];
        self.selectedIndexPath = nil;
        
        [self downloadRemoteFile:item.filePath toFolder:[selectedFolder lastObject]];
        [self dismissViewControllerAnimated:YES completion:NULL];
    };
    
    filePicker.cancellationBlock = ^{
        [self dismissViewControllerAnimated:YES completion:NULL];
    };
    
    [self presentViewController:filePicker animated:YES completion:NULL];
}

-(void)downloadRemoteFile:(NSString*)remotePath toFolder:(NSString*)folder{
    
}

-(void)uploadSelectedFiles:(NSArray*)selectedFiles{
    
}

#pragma mark - scroll delegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

@end
