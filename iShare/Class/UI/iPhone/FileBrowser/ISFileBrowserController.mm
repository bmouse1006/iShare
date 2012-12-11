//
//  FileBrowserController.m
//  iShare
//
//  Created by Jin Jin on 12-8-3.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISFileBrowserController.h"
#import "FileBrowserDataSource.h"
#import "BWStatusBarOverlay.h"
#import "SVProgressHUD.h"
#import "FileOperationWrap.h"
#import "FilePickerViewController.h"
#import "ISFileQuickPreviewController.h"
#import "MWPhotoBrowser.h"
#import "ISPhotoBrowserDelegate.h"
#import "CustomUIComponents.h"
#import "MDAudioPlayerController.h"
#import "MDAudioFile.h"
#import "ISFileBrowserCellInterface.h"
#import "ISFileBrowserCell.h"
#import "ISFileBrowserMenuCell.h"
#import "TextEditorViewController.h"
#import "ISFileBrowserCellInterface.h"
//#import "JJMediaPlayerController.h"
#import "LZMAExtractor.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MessageUI/MessageUI.h>

#define kNewDirectoryNameAlertViewTag 100
#define kNewTextFileNameAlertViewTag 200
#define kDeleteFilesConfirmAlertViewTag 300
#define kRenameAlertViewTag 400
#define kPasswordInputForRARAlertViewTag 500
#define kPasswordInputForZipAlertViewTag 600

@interface ISFileBrowserController ()

@property (nonatomic, copy) NSString* filePath;
@property (nonatomic, copy) NSString* filePathToBeProcessed;
@property (nonatomic, strong) FileBrowserDataSource* dataSource;
@property (nonatomic, strong) QuadCurveMenu* pathMenu;
@property (nonatomic, strong) UIDocumentInteractionController* documentInteractionController;

@end

@implementation ISFileBrowserController

static CGFloat kMessageTransitionDuration = 1.5f;

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(id)initWithFilePath:(NSString*)filePath{
    
    self = [super initWithNibName:@"ISFileBrowserController" bundle:nil];
    
    if (self){
        BOOL isDirectory;
        BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
        
        if (filePath == nil || exists == NO || (exists == YES && isDirectory == NO)){
            self.filePath = [[FileOperationWrap sharedWrap] homePath];
            self.title = NSLocalizedString(@"tab_title_home", nil);
        }else{
            self.filePath = filePath;
            self.title = [filePath lastPathComponent];
        }
        
        self.tabBarItem.image = [UIImage imageNamed:@"ic_tab_myfiles"];
        self.tabBarItem.title = NSLocalizedString(@"tab_title_myfiles", nil);
        
        self.dataSource = [[FileBrowserDataSource alloc] initWithFilePath:self.filePath];
        
        [self registorNotifications];
        
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //add path menu
    [self loadQuadCurveMenu];
    
    //customize title of action buttons
    [self.actionButton setTitle:NSLocalizedString(@"btn_title_operate", nil)];
    [self.deleteButton setTitle:NSLocalizedString(@"btn_title_delete",nil)];
    [self.moveButton setTitle:NSLocalizedString(@"btn_title_move", nil)];
    [self.duplicateButton setTitle:NSLocalizedString(@"btn_title_copyto", nil)];
    [self.selectAllButton setTitle:NSLocalizedString(@"btn_title_selectall", nil)];
    
    [self.doneEditButton setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [self.deleteButton setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [self.deleteButton setTintColor:[UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1]];
    
    self.navigationItem.rightBarButtonItem = self.actionButton;
    //search field
    UIImage* searchBack = [UIImage imageNamed:@"searches_field"];
    UIImage* resizableBack = [searchBack resizableImageWithCapInsets:UIEdgeInsetsMake(0, 25, 0, 14)];
    self.searchField.background = resizableBack;
    UIView* leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 28, 44)];
    leftView.backgroundColor = [UIColor clearColor];
    self.searchField.leftView = leftView;
    self.searchField.leftViewMode = UITextFieldViewModeAlways;
    self.searchField.placeholder = NSLocalizedString(@"search_placeholder", nil);
    [self.searchField addTarget:self action:@selector(searchFieldValueChanged:) forControlEvents:UIControlEventEditingChanged];
    //segment bar
    [self.typeSegmented setTitle:NSLocalizedString(@"seg_title_name", nil) forSegmentAtIndex:0];
    [self.typeSegmented setTitle:NSLocalizedString(@"seg_title_date", nil) forSegmentAtIndex:1];
    [self.typeSegmented setTitle:NSLocalizedString(@"seg_title_type", nil) forSegmentAtIndex:2];
    self.typeSegmented.selectedSegmentIndex = 2;
    //view background color
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_texture"]];
    //table view
//    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.backgroundView = nil;
    self.tableView.tableHeaderView = self.tableHeaderView;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 50, 0);
    self.tableView.rowHeight = 60.0f;
    
    self.refreshView = [[[NSBundle mainBundle] loadNibNamed:@"TableHeaderRefreshView" owner:nil options:nil] objectAtIndex:0];
    self.refreshView.backgroundColor = [UIColor clearColor];
    self.refreshView.title = NSLocalizedString(@"refresh_title", nil);
    self.refreshView.readyTitle = NSLocalizedString(@"refresh_readytitle", nil);
    self.refreshView.refreshTitle = NSLocalizedString(@"refresh_refreshtitle", nil);
    self.refreshView.textLabel.textColor = [UIColor grayColor];
    self.refreshView.textLabel.shadowColor = [UIColor whiteColor];
    self.refreshView.textLabel.shadowOffset = CGSizeMake(0, 1);
    self.refreshView.textLabel.font = [UIFont boldSystemFontOfSize:14];
    
    [self.tableView addSubview:self.refreshView];

    self.tableView.dataSource = self.dataSource;
    
    [self typeSegmentClicked:self.typeSegmented];

    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.tableView = nil;
    self.pathMenu = nil;
    self.tableHeaderView = nil;
    self.deleteButton = nil;
    self.moveButton = nil;
    self.doneEditButton = nil;
    self.duplicateButton = nil;
    self.actionButton = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    //lay out subviews
    self.tableView.frame = self.view.bounds;
    
    CGRect frame = self.pathMenu.frame;
    frame.origin.y = self.view.bounds.size.height - frame.size.height;
    
    self.pathMenu.frame = frame;
    
    frame = self.refreshView.frame;
    frame.origin.y = -frame.size.height;
    self.refreshView.frame = frame;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.tableView.visibleCells enumerateObjectsUsingBlock:^(UITableViewCell* cell, NSUInteger idx, BOOL* stop){
        if ([cell conformsToProtocol:NSProtocolFromString(@"ISFileBrowserCellInterface")]){
            [(id<ISFileBrowserCellInterface>)cell updateCell];
        }
    }];
    
    if (self.tableView.editing == NO){
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    }
    
    [self.dataSource refresh];
    [self.tableView reloadData];
}

#pragma mark - tableview delegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    FileItem* item = [self.dataSource objectAtIndexPath:indexPath];
    if (item.type == FileItemTypeActionMenu){
        return 40.0f;
    }else{
        return 60.0f;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.searchField resignFirstResponder];
    if (tableView.editing == NO){
        FileItem* item = [self.dataSource objectAtIndexPath:indexPath];
        if (item.type == FileItemTypeActionMenu){
            return;
        }
        FileContentType fileType = [[FileOperationWrap sharedWrap] fileTypeWithFilePath:item.filePath];
        //normal mode
        switch (fileType) {
            case FileContentTypeDirectory:
            {
                ISFileBrowserController* fileBrowser = [[ISFileBrowserController alloc] initWithFilePath:item.filePath];
                [self.navigationController pushViewController:fileBrowser animated:YES];
            }
                break;
            case FileContentTypePDF:
            {
                ReaderDocument* document = [ReaderDocument withDocumentFilePath:item.filePath password:nil];
                ReaderViewController* pdfReader = [[ReaderViewController alloc] initWithReaderDocument:document];
                pdfReader.delegate = self;
                self.hidesBottomBarWhenPushed = YES;
                [self.navigationController setNavigationBarHidden:YES animated:YES];
                [self.navigationController pushViewController:pdfReader animated:YES];
            }
                break;
            case FileContentTypeImage:
            {
                NSArray* imagePaths = [[FileOperationWrap sharedWrap] allImagePathsInFolder:self.filePath];
                NSInteger startIndex = [imagePaths indexOfObject:item.filePath];
                ISPhotoBrowserDelegate* delegate = [[ISPhotoBrowserDelegate alloc] initWithImageFilePaths:imagePaths];
                MWPhotoBrowser* photoBrowser = [[MWPhotoBrowser alloc] initWithDelegate:delegate];
                photoBrowser.displayActionButton = YES;
                [photoBrowser setInitialPageIndex:startIndex];
                [self.navigationController pushViewController:photoBrowser animated:YES];
            }
                break;
            case FileContentTypeZip:
            {
                //should be unzip...
                [self unzipFileItem:item];
            }
                break;
            case FileContentTypeRAR:
            {//handl rar file
                [self handleRARFileItem:item];
            }
                break;
            case FileContentType7Zip:
            {//handle 7zip file
                [self handle7ZipFileItem:item];
            }
                break;
            case FileContentTypeAppleMovie:
            {
                //当前先调用系统自带视频播放器
                MPMoviePlayerViewController* moviePlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:item.filePath]];
                [self presentMoviePlayerViewControllerAnimated:moviePlayer];
//                JJMediaPlayerController* controller = [[JJMediaPlayerController alloc] initWithFilepath:item.filePath];
//                [self.navigationController pushViewController:controller animated:YES];
            }
                break;
            case FileContentTypeMusic:
            {
                
                MDAudioFile* audioFile = [[MDAudioFile alloc] initWithPath:[NSURL fileURLWithPath:item.filePath]];
                
                JJAudioPlayerManager* manager = [JJAudioPlayerManager sharedManager];
                
                [manager addToDefaultPlayList:audioFile playNow:YES];
                
                MDAudioPlayerController* musicPlayer = [[MDAudioPlayerController alloc] initWithAudioPlayerManager:manager];
                
                [self.navigationController pushViewController:musicPlayer animated:YES];
            }
                break;
            case FileContentTypeText:
            {
//                ISFileQuickPreviewController* previewController = [[ISFileQuickPreviewController alloc] initWithPreviewItems:@[item]];
//                [self.navigationController pushViewController:previewController animated:YES];
                TextEditorViewController* textEditor = [[TextEditorViewController alloc] initWithFilePath:item.filePath];
                [self.navigationController pushViewController:textEditor animated:YES];
            }
                break;
            case FileContentTypeOther:
            {
                if ([QLPreviewController canPreviewItem:item]){
                    ISFileQuickPreviewController* previewController = [[ISFileQuickPreviewController alloc] initWithPreviewItems:@[item]];
                    [self.navigationController pushViewController:previewController animated:YES];
                }/*else{
                    JJMediaPlayerController* controller = [[JJMediaPlayerController alloc] initWithFilepath:item.filePath];
                    [self.navigationController pushViewController:controller animated:YES];
                }*/
            }
                break;
            default:
                break;
        }
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    }else{
        //editing mode
        NSArray* selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
        if ([selectedIndexPaths count] > 0){
            [self enableActionButtons];
        }
    }
    
    [self.dataSource hideMenu];
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView.editing == YES){
        NSArray* selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
        if ([selectedIndexPaths count] == 0){
            [self disableActionButtons];
        }
    }
}

-(void)enableActionButtons{
    self.moveButton.enabled = YES;
    self.duplicateButton.enabled = YES;
    self.deleteButton.enabled = YES;
}

-(void)disableActionButtons{
    self.moveButton.enabled = NO;
    self.duplicateButton.enabled = NO;
    self.deleteButton.enabled = NO;
}

#pragma mark - scroll view delegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [self.searchField resignFirstResponder];
    if (self.dataSource.menuIsShown){
        [self.dataSource hideMenu];
    }
    //
    if (self.tableView.contentOffset.y <  -self.refreshView.frame.size.height){
        [self.refreshView changeToRefreshStatus:TableHeaderRefreshViewStatusReady];
    }else{
        [self.refreshView changeToRefreshStatus:TableHeaderRefreshViewStatusNormal];
    }
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (self.refreshView.status == TableHeaderRefreshViewStatusReady){
        //start refresh
        [self.dataSource refresh];
        [self.tableView reloadData];
    }
}

#pragma mark - button action
-(IBAction)actionButtonIsClicked:(id)sender{
    [self.searchField resignFirstResponder];
    [self.dataSource hideMenu];
    //enable edit mode
    [self startEditingMode];
}

-(IBAction)typeSegmentClicked:(id)sender{
    [self.searchField resignFirstResponder];
    UISegmentedControl* segControl = (UISegmentedControl*)sender;
    [self.dataSource sortListByOrder:(FileBrowserDataSourceOrder)segControl.selectedSegmentIndex];
    [self.tableView reloadData];
}

-(IBAction)searchFieldValueChanged:(id)sender{
    [self.dataSource setFilterKeyword:self.searchField.text];
    [self.tableView reloadData];
}

-(IBAction)doneEditButtonClicked:(id)sender{
    [self endEditingMode];
}

-(IBAction)moveButtonClicked:(id)sender{
    FilePickerViewController* picker = [[FilePickerViewController alloc] initWithFilePath:nil filterType:FileContentTypeDirectory];
    picker.completionBlock = ^(NSArray* selectedPaths){
        NSString* toPath = [selectedPaths lastObject];
        if ([self.filePath isEqualToString:toPath] == NO && toPath.length > 0){
            NSArray* indexPaths = [self.tableView indexPathsForSelectedRows];
            [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath* indexPath, NSUInteger idx, BOOL* stop){
                NSString* file = [self.dataSource objectAtIndexPath:indexPath].filePath;
                NSString* filename = [file lastPathComponent];
                [[NSFileManager defaultManager] moveItemAtPath:file toPath:[toPath stringByAppendingPathComponent:filename] error:NULL];
            }];
            
            [self.dataSource refresh];
            [self.tableView reloadData];
            double delayInSeconds = 0.1;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self endEditingMode];
            });
        }
        
        [self dismissViewControllerAnimated:YES completion:NULL];
    };
    
    picker.cancellationBlock = ^{
        [self dismissViewControllerAnimated:YES completion:NULL];
    };
    
    [self presentViewController:picker animated:YES completion:NULL];
}

-(IBAction)duplicateButtonClicked:(id)sender{
    FilePickerViewController* picker = [[FilePickerViewController alloc] initWithFilePath:nil filterType:FileContentTypeDirectory];
    picker.completionBlock = ^(NSArray* selectedPaths){
        NSString* toPath = [selectedPaths lastObject];
        if ([self.filePath isEqualToString:toPath] == NO && toPath.length > 0){
            NSArray* indexPaths = [self.tableView indexPathsForSelectedRows];
            [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath* indexPath, NSUInteger idx, BOOL* stop){
                NSString* file = [self.dataSource objectAtIndexPath:indexPath].filePath;
                NSString* filename = [file lastPathComponent];
                [[NSFileManager defaultManager] copyItemAtPath:file toPath:[toPath stringByAppendingPathComponent:filename] error:NULL];
            }];
            
            [self.dataSource refresh];
            [self.tableView reloadData];
            double delayInSeconds = 0.1;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self endEditingMode];
            });
        }
        [self dismissViewControllerAnimated:YES completion:NULL];
    };
    
    picker.cancellationBlock = ^{
        [self dismissViewControllerAnimated:YES completion:NULL];
    };
    
    [self presentViewController:picker animated:YES completion:NULL];
}

-(IBAction)deleteButtonClicked:(id)sender{
    //show confirm alert view
    UIAlertView* deleteConfirmAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"alert_title_deleteconfirm", nil) message:NSLocalizedString(@"alert_message_deleteconfirm", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"btn_title_cancel", nil) otherButtonTitles:NSLocalizedString(@"btn_title_confirm", nil), nil];
    deleteConfirmAlert.tag = kDeleteFilesConfirmAlertViewTag;
    
    [deleteConfirmAlert show];
}

-(IBAction)selectAllButtonClicked:(id)sender{
    for (int section = 0; section < [self.dataSource numberOfSectionsInTableView:self.tableView]; section++){
        for (int row = 0; row < [self.dataSource tableView:self.tableView numberOfRowsInSection:section]; row++){
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }
    
    [self enableActionButtons];
}

#pragma mark - Quad Cure Menu

-(void)loadQuadCurveMenu{
    
    UIImage* bkImage = [UIImage imageNamed:@"bg-menuitem"];
    UIImage* bkHighlightedImage = [UIImage imageNamed:@"bg-menuitem-highlighted"];
    [self.pathMenu removeFromSuperview];
    QuadCurveMenuItem* newDirectory = [[QuadCurveMenuItem alloc] initWithImage:bkImage highlightedImage:bkHighlightedImage ContentImage:[UIImage imageNamed:@"icon_folder"] highlightedContentImage:[UIImage imageNamed:@"icon_folder_highlighted"]];
    QuadCurveMenuItem* newAlbumPhoto = [[QuadCurveMenuItem alloc] initWithImage:bkImage highlightedImage:bkHighlightedImage ContentImage:[UIImage imageNamed:@"icon_film"]  highlightedContentImage:[UIImage imageNamed:@"icon_film_highlighted"] ];
    QuadCurveMenuItem* newCameraPhoto = [[QuadCurveMenuItem alloc] initWithImage:bkImage highlightedImage:bkHighlightedImage ContentImage:[UIImage imageNamed:@"icon_photo"]  highlightedContentImage:[UIImage imageNamed:@"icon_photo_highlighted"] ];
    QuadCurveMenuItem* newText = [[QuadCurveMenuItem alloc] initWithImage:bkImage highlightedImage:bkHighlightedImage ContentImage:[UIImage imageNamed:@"icon_textfile"]  highlightedContentImage:[UIImage imageNamed:@"icon_textfile_highlighted"]];
    
    NSArray* menus = @[newDirectory, newAlbumPhoto, newCameraPhoto, newText];
    
    self.pathMenu = [[QuadCurveMenu alloc] initWithFrame:CGRectMake(0, 0, 320, 50) menus:menus];
    self.pathMenu.startPoint = CGPointMake(25, 25);
    self.pathMenu.menuWholeAngle = M_PI*2/3;
    self.pathMenu.delegate = self;
    
    [self.view addSubview:self.pathMenu];
}

-(void)quadCurveMenu:(QuadCurveMenu *)menu didSelectIndex:(NSInteger)idx{
    //path menu is selected
    switch (idx) {
        case 0:
            //add new directory
            [self promptToCreateNewDirectory];
            break;
        case 1:
            //add new album photo
            [self promptToCreateNewImageFromAlbum];
            break;
        case 2:
            //add new camera photo
            [self promptToCreateNewImageFromCamera];
            break;
        case 3:
            //add new text file
            [self promptToCreateTextFile];
            break;
        default:
            break;
    }
}

#pragma mark - add action
-(void)promptToCreateNewDirectory{
    //show alert view to input name of directory
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"alert_title_inputdirectoryname", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"btn_title_cancel", nil) otherButtonTitles:NSLocalizedString(@"btn_title_confirm", nil),nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    alertView.tag = kNewDirectoryNameAlertViewTag;
    
    [alertView show];
}

-(void)promptToCreateNewImageFromAlbum{
    UIImagePickerController* imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.delegate = self;
    
    [self presentViewController:imagePicker animated:YES completion:NULL];
}

-(void)promptToCreateNewImageFromCamera{
    if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear] == NO &&
        [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront] == NO){
        return;
    }
    UIImagePickerController* camera = [[UIImagePickerController alloc] init];
    camera.sourceType = UIImagePickerControllerSourceTypeCamera;
    camera.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    camera.delegate = self;
    
    [self presentViewController:camera animated:YES completion:NULL];
}

-(void)promptToCreateTextFile{
    //show alert view to input name of text file
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"alert_title_inputtextfilename", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"btn_title_cancel", nil) otherButtonTitles:NSLocalizedString(@"btn_title_confirm", nil),nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    alertView.tag = kNewTextFileNameAlertViewTag;
    
    [alertView show];
}

#pragma mark - image picker delegate

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage* pickedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSData* imageData = UIImagePNGRepresentation(pickedImage);
    
    NSString* fileName = [self generateImageName];
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"status_message_savingimage", nil)];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL result = [[FileOperationWrap sharedWrap] saveFile:imageData withName:fileName path:self.filePath];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result){
                [BWStatusBarOverlay showSuccessWithMessage:NSLocalizedString(@"status_message_newimagecreated", nil) duration:kMessageTransitionDuration animated:YES];
                [self.dataSource refresh];
                [self.tableView reloadData];
                [SVProgressHUD dismissWithSuccess:NSLocalizedString(@"status_message_savingsuccess", nil)];
            }else{
                [BWStatusBarOverlay showSuccessWithMessage:NSLocalizedString(@"status_message_newimagecreatefailed", nil) duration:kMessageTransitionDuration animated:YES];
                [SVProgressHUD dismissWithError:NSLocalizedString(@"status_message_savingfailed", nil)];
            }
            [self dismissViewControllerAnimated:YES completion:NULL];
        });
    });
}

-(NSString*)generateImageName{
    NSString* filenameTemplate = NSLocalizedString(@"newimagename_template", nil);
    
    NSString* actualName = [NSString stringWithFormat:filenameTemplate, [[NSDate date] descriptionWithLocale:[NSLocale currentLocale]]];
    
    return [actualName stringByAppendingPathExtension:@"png"];
}

#pragma mark - alert view delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (alertView.tag) {
        case kNewDirectoryNameAlertViewTag:
        {
            //create new directory
            if (buttonIndex == 1){
                //confirm
                UITextField* textField = [alertView textFieldAtIndex:0];
                NSString* folderName = textField.text;
                if ([[FileOperationWrap sharedWrap] createDirectoryWithName:folderName path:self.filePath]){
                    //notify create success
                    [BWStatusBarOverlay showSuccessWithMessage:NSLocalizedString(@"status_message_newfoldercreated", nil) duration:kMessageTransitionDuration animated:YES];
                    //reload tableview
                    [self.dataSource refresh];
                    [self.tableView reloadData];
                }else{
                    //notify create failed
                    [BWStatusBarOverlay showSuccessWithMessage:NSLocalizedString(@"status_message_newfoldercreatefailed", nil) duration:kMessageTransitionDuration animated:YES];
                }
            }
        }
            break;
        case kNewTextFileNameAlertViewTag:
        {
            //create new text file
            if (buttonIndex == 1){
                //confirm
                UITextField* textField = [alertView textFieldAtIndex:0];
                NSString* fileName = textField.text;
                NSString* fullname = [fileName stringByAppendingPathExtension:@"txt"];
                
                if ([[FileOperationWrap sharedWrap] createFileWithName:fullname path:self.filePath]){
                    //notify create success
                    [BWStatusBarOverlay showSuccessWithMessage:NSLocalizedString(@"status_message_newtextcreated", nil) duration:kMessageTransitionDuration animated:YES];
                    //reload tableview
                    [self.dataSource refresh];
                    [self.tableView reloadData];
                }else{
                    //notify create failed
                    [BWStatusBarOverlay showSuccessWithMessage:NSLocalizedString(@"status_message_newtextcreatefailed", nil) duration:kMessageTransitionDuration animated:YES];
                }
            }
        }
            break;
        case kDeleteFilesConfirmAlertViewTag:
        {
            if (buttonIndex == 1){
                //confirm deletion
                //show waiting alert view
                [self removeFilesForIndexPaths:[self.tableView indexPathsForSelectedRows]];
                [self disableActionButtons];
            }
        }
            break;
        case kRenameAlertViewTag:
        {
            if (buttonIndex == 1){
                UITextField* textField = [alertView textFieldAtIndex:0];
                NSString* newFilePath = [self.filePath stringByAppendingPathComponent:textField.text];
                
                //did rename for no change and empty
                if ([newFilePath compare:self.filePathToBeProcessed] == NSOrderedSame || textField.text.length == 0){
                    return;
                }
                
                NSError* error = nil;
                
                if ([[NSFileManager defaultManager] moveItemAtPath:self.filePathToBeProcessed toPath:newFilePath error:&error]){
                    //success
                    [self.dataSource refresh];
                    [self.tableView reloadData];
                }else{
                    //failed
                    UIAlertView* renameFailed = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"alert_message_renamefailed", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"btn_title_iknow", nil) otherButtonTitles: nil];
                    [renameFailed show];
                }
            }
        }
            break;
        case kPasswordInputForRARAlertViewTag:
        {//input password for rar file
            if (buttonIndex == 1){
                //confirm
                UITextField* passwordField = [alertView textFieldAtIndex:0];
                NSString* password = passwordField.text;
                //try again using password
                [self unRARFileAtPath:self.filePathToBeProcessed withPassword:password];
            }else{
                [SVProgressHUD dismiss];
            }
        }
            break;
        case kPasswordInputForZipAlertViewTag:
        {
            if (buttonIndex == 1){
                //confirm
                UITextField* passwordField = [alertView textFieldAtIndex:0];
                NSString* password = passwordField.text;
                [self unzipFilePath:self.filePathToBeProcessed withPassword:password];
            }else{
                [SVProgressHUD dismiss];
            }
        }
            break;
        default:
            break;
    }
}

#pragma mark - text field delegate
-(void)textFieldDidEndEditing:(UITextField *)textField{
    [textField resignFirstResponder];
}

#pragma mark - document interaction delegate

-(UIViewController*)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller{
    return self;
}

- (BOOL)documentInteractionController:(UIDocumentInteractionController *)controller canPerformAction:(SEL)action{
    return YES;
}

#pragma mark - create file and folder

-(void)removeFilesForIndexPaths:(NSArray*)indexPaths{
    NSMutableArray* filePaths = [NSMutableArray array];
    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath* indexPath, NSUInteger idx, BOOL* stop){
        FileItem* item = [self.dataSource objectAtIndexPath:indexPath];
        [filePaths addObject:item.filePath];
    }];
    
    [[FileOperationWrap sharedWrap] removeFileItems:filePaths withCompletionBlock:^(BOOL finished){
        [self.dataSource refresh];
        [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

#pragma mark - editing mode
-(void)startEditingMode{
    //show top bar buttons
    self.navigationItem.title = nil;
    [self.navigationItem setRightBarButtonItem:self.doneEditButton animated:YES];
    NSArray* leftItems = @[self.duplicateButton, self.moveButton, self.deleteButton, self.selectAllButton];
    [self.navigationItem setLeftBarButtonItems:leftItems animated:YES];
    [self disableActionButtons];
    //hide path menu
    [UIView animateWithDuration:0.2f animations:^{
        self.pathMenu.alpha = 0.0f;
    }];
    //change table view to editing mode
    [self.tableView setEditing:YES animated:YES];
}

-(void)endEditingMode{
    //hide top bar buttons;
    self.navigationItem.title = self.title;
    [self.navigationItem setRightBarButtonItem:self.actionButton animated:YES];
    [self.navigationItem setLeftBarButtonItems:nil animated:YES];
    //show path menu
    [UIView animateWithDuration:0.2f animations:^{
        self.pathMenu.alpha = 1.0f;
    }];
    //exit editing mode
    [self.tableView setEditing:NO animated:YES];
}

#pragma mark - notification selector
-(void)registorNotifications{
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(shouldShowMenu:) name:NOTIFICATION_FILEBROWSER_MENUSHOWN object:self.dataSource];
    [nc addObserver:self selector:@selector(shouldHideMenu:) name:NOTIFICATION_FILEBROWSER_MENUGONE object:self.dataSource];
    [nc addObserver:self selector:@selector(deleteFileNotificationReceived:) name:NOTIFICATION_FILEBROWSER_DELETEBUTTONCLICKED object:self.dataSource];
    [nc addObserver:self selector:@selector(openFileNotificationReceived:) name:NOTIFICAITON_FILEBROWSER_OPENINBUTTONCLICKED object:self.dataSource];
    [nc addObserver:self selector:@selector(mailFileNotificationReceived:) name:NOTIFICATION_FILEBROWSER_MAILBUTTONCLICKED object:self.dataSource];
    [nc addObserver:self selector:@selector(renameFileNotificationReceived:) name:NOTIFICATION_FILEBROWSER_RENAMEBUTTONCLICKED object:self.dataSource];
    [nc addObserver:self selector:@selector(zipFileNotificationReceived:) name:NOTIFICATION_FILEBROWSER_ZIPBUTTONCLICKED object:self.dataSource];
}

-(void)deleteFileNotificationReceived:(NSNotification*)notification{
    
    FileItem* item = [notification.userInfo objectForKey:@"item"];
    NSArray* filePaths = [NSArray arrayWithObject:item.filePath];
    
    [[FileOperationWrap sharedWrap] removeFileItems:filePaths withCompletionBlock:^(BOOL finished){
        
        NSIndexPath* menuRow = [self.dataSource menuIndex];
        NSIndexPath* fileRow = [NSIndexPath indexPathForRow:menuRow.row - 1 inSection:menuRow.section];
        
        FileItem* fileItem = [self.dataSource objectAtIndexPath:fileRow];
        [self.dataSource removeFileItem:item];
        [self.dataSource removeFileItem:fileItem];
        
        [self.tableView deleteRowsAtIndexPaths:@[fileRow, menuRow] withRowAnimation:UITableViewRowAnimationFade];
    }];
}

-(void)openFileNotificationReceived:(NSNotification*)notification{
    FileItem* item = [notification.userInfo objectForKey:@"item"];
    NSURL* URL = [NSURL fileURLWithPath:item.filePath];

    [self setupDocumentInteractionWithURL:URL];

    UIViewController* rootController = [UIApplication sharedApplication].keyWindow.rootViewController;
    BOOL result = [self.documentInteractionController presentOpenInMenuFromRect:rootController.view.bounds inView:rootController.view animated:YES];
    if (result == NO){
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"alert_message_nosuitableapp", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
    }
}

-(void)mailFileNotificationReceived:(NSNotification*)notification{
    FileItem* item = [notification.userInfo objectForKey:@"item"];
    NSString* filename = [[item filePath] lastPathComponent];
    if ([MFMailComposeViewController canSendMail]){
        //get zipped file
        [SVProgressHUD showWithStatus:NSLocalizedString(@"progress_message_zipping", nil)];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString* zippedFilePath = [[FileOperationWrap sharedWrap] zipFileAtFilePath:item.filePath toPath:[[FileOperationWrap sharedWrap] tempFolder]];
            NSData* zippedData = [NSData dataWithContentsOfFile:zippedFilePath];
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                MFMailComposeViewController* mailController = [[MFMailComposeViewController alloc] init];
                mailController.mailComposeDelegate = self;
                [mailController setSubject:filename];
                [mailController addAttachmentData:zippedData mimeType:@"application/zip" fileName:[filename stringByAppendingPathExtension:@"zip"]];
                
                [self presentViewController:mailController animated:YES completion:NULL];
            });
        });

    }else{
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"alert_message_nomailaccount", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
    }
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    [self dismissViewControllerAnimated:YES completion:NULL];
    [self.dataSource refresh];
    [self.tableView reloadData];
}

-(void)renameFileNotificationReceived:(NSNotification*)notification{
    FileItem* item = [notification.userInfo objectForKey:@"item"];
    self.filePathToBeProcessed = item.filePath;
    
    UIAlertView* renameAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"alert_title_rename", nil) message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"btn_title_cancel", nil) otherButtonTitles:NSLocalizedString(@"btn_title_confirm", nil), nil];
    renameAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    renameAlert.tag = kRenameAlertViewTag;
    
    UITextField* textField = [renameAlert textFieldAtIndex:0];
    
    NSString* fileName = [item.filePath lastPathComponent];
    NSString* fileExtension = [fileName pathExtension];
    
    NSInteger selectLength = 0;
    if (fileExtension.length > 0){
        selectLength = [fileName length] - [fileExtension length] - 1;
    }
    
    textField.text = fileName;
    UITextPosition* start = [textField beginningOfDocument];
    UITextPosition* end = [textField positionFromPosition:start offset:selectLength];
    UITextRange* selectRange = [textField textRangeFromPosition:start toPosition:end];
    
    [textField setSelectedTextRange:selectRange];
    
    [renameAlert show];
}

-(void)zipFileNotificationReceived:(NSNotification*)notification{
    FileItem* item = [notification.userInfo objectForKey:@"item"];
    
    [self zipFileItem:item];
}

-(void)zipFileItem:(FileItem*)item{
    [SVProgressHUD showWithStatus:NSLocalizedString(@"progress_message_zipping", nil)];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString* zippedFilename = [[FileOperationWrap sharedWrap] zipFileAtFilePath:item.filePath toPath:self.filePath];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (zippedFilename.length >0){
                [self.dataSource refresh];
                [self.tableView reloadData];
            }
            [SVProgressHUD dismiss];
        });
    });
}

-(void)handleRARFileItem:(FileItem*)item{
    DebugLog(@"handle RAR file");
    [self unRARFileAtPath:item.filePath withPassword:nil];
}

-(void)unRARFileAtPath:(NSString*)filePath withPassword:(NSString*)password{
    [SVProgressHUD showWithStatus:NSLocalizedString(@"progress_message_unzipping", nil)];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            [[FileOperationWrap sharedWrap] unrarFileAtFilePath:filePath
                                                       toFolder:self.filePath
                                                   withPassword:password];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.dataSource refresh];
                [self.tableView reloadData];
                [SVProgressHUD dismiss];
            });
        }
        @catch (RARExtractException *exception) {
            switch (exception.status) {
                case RARArchiveProtected:
                {
                    self.filePathToBeProcessed = filePath;
                    //promote a alert view to input password
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil
                                                                        message:NSLocalizedString(@"alert_message_pleaseinputpassword", nil)
                                                                       delegate:self
                                                              cancelButtonTitle:NSLocalizedString(@"btn_title_cancel", nil)
                                                              otherButtonTitles:NSLocalizedString(@"btn_title_confirm", nil), nil];
                        alert.tag = kPasswordInputForRARAlertViewTag;
                        alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
                        [alert show];
                    });
                }
                    break;
                default:
                    [SVProgressHUD dismissWithError:NSLocalizedString(@"alert_message_raruncompressfailed", nil)];
                    break;
            }
        }
    });
}

-(void)handle7ZipFileItem:(FileItem*)item{

    [SVProgressHUD showWithStatus:NSLocalizedString(@"progress_message_unzipping", nil)];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //creating a tempfolder
        NSString* tempFolder = [[[FileOperationWrap sharedWrap] tempFolder] stringByAppendingPathComponent:@"7zTemp"];
        NSFileManager* fm = [NSFileManager defaultManager];
        //remove this fodler and recreate again
        //in order to clean any files
        [fm removeItemAtPath:tempFolder error:NULL];
        [fm createDirectoryAtPath:tempFolder withIntermediateDirectories:NO attributes:nil error:NULL];
        //extrating files to temp folder
        NSArray* results = [LZMAExtractor extract7zArchive:item.filePath tmpDirName:tempFolder];
        //move everything in this temp folder to current working folder
        [results enumerateObjectsUsingBlock:^(NSString* filePath, NSUInteger idx, BOOL* stop){
            NSString* filename = [filePath lastPathComponent];
            NSString* destPath = [self.filePath stringByAppendingPathComponent:filename];
            [fm moveItemAtPath:filePath toPath:destPath error:NULL];
        }];
        //remove temp folder
        [fm removeItemAtPath:tempFolder error:NULL];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.dataSource refresh];
            [self.tableView reloadData];
            [SVProgressHUD dismiss];
        });
    });
}

-(void)unzipFileItem:(FileItem*)item{
    
    if ([[FileOperationWrap sharedWrap] isEncryptedZipFile:item.filePath]){
        //promote need password alert
        self.filePathToBeProcessed = item.filePath;
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"alert_message_pleaseinputpassword", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"btn_title_cancel", nil)
                                              otherButtonTitles:NSLocalizedString(@"btn_title_confirm", nil), nil];
        alert.tag = kPasswordInputForZipAlertViewTag;
        alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
        [alert show];
    }else{
        //unzip directly
        [self unzipFilePath:item.filePath withPassword:nil];
    }
}

-(void)unzipFilePath:(NSString*)filePath withPassword:(NSString*)password{
    [SVProgressHUD showWithStatus:NSLocalizedString(@"progress_message_unzipping", nil)];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL result = [[FileOperationWrap sharedWrap] unzipFileAtFilePath:filePath
                                                                   toPath:self.filePath
                                                             withPassword:password];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result){
                [self.dataSource refresh];
                [self.tableView reloadData];
                [SVProgressHUD dismiss];
            }else{
                [SVProgressHUD dismissWithError:NSLocalizedString(@"progress_message_unzippingfailed", nil)];
            }
        });
    });
}

-(void)shouldShowMenu:(NSNotification*)notification{
    [self refreshTableView];
}

-(void)shouldHideMenu:(NSNotification*)notification{
    [self refreshTableView];
}

-(void)refreshTableView{
    [self.tableView beginUpdates];
    
    if (self.dataSource.removeIndex != NSNotFound){
        NSIndexPath* removeIndexPath = [NSIndexPath indexPathForRow:self.dataSource.removeIndex inSection:0];
        [self.tableView deleteRowsAtIndexPaths:@[ removeIndexPath ] withRowAnimation:UITableViewRowAnimationFade];
    }
    
    if (self.dataSource.addIndex != NSNotFound){
        NSIndexPath* addIndexPath = [NSIndexPath indexPathForRow:self.dataSource.addIndex inSection:0];
        [self.tableView insertRowsAtIndexPaths:@[ addIndexPath ] withRowAnimation:UITableViewRowAnimationFade];
    }
    
    [self.tableView endUpdates];
}

#pragma mark - document interaction
-(void)setupDocumentInteractionWithURL:(NSURL*)URL{
    if (self.documentInteractionController == nil){
        self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:URL];
        self.documentInteractionController.delegate = self;
    }else{
        self.documentInteractionController.URL = URL;
    }
}

#pragma mark - PDF reader delegate
-(void)dismissReaderViewController:(ReaderViewController *)viewController{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.hidesBottomBarWhenPushed = NO;
    [self.navigationController popViewControllerAnimated:YES];
}

@end
