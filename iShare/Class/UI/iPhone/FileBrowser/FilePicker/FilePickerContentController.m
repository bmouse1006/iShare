//
//  FilePickerContentController.m
//  iShare
//
//  Created by Jin Jin on 12-8-12.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "FilePickerContentController.h"
#import "FileOperationWrap.h"
#import "FileItem.h"

@interface FilePickerContentController ()

@property (nonatomic, strong) FilePickerDataSource* dataSource;
@property (nonatomic, assign) FileContentType type;

@end

@implementation FilePickerContentController

-(id)initWithFilePath:(NSString*)filePath filterType:(FileContentType)type{
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    
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
        self.type = type;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    switch (self.type) {
        case FileContentTypeDirectory:
            self.tableView.allowsMultipleSelection = NO;
            break;
        default:
            self.tableView.allowsMultipleSelectionDuringEditing = YES;
            self.tableView.editing = YES;
            break;
    }

    self.doneButton.title = NSLocalizedString(@"btn_title_confirm", nil);
    [self.doneButton setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    self.cancelButton.title = NSLocalizedString(@"btn_title_cancel", nil);
    
    self.navigationItem.rightBarButtonItems = @[self.doneButton, self.cancelButton];
    
    self.dataSource = [[FilePickerDataSource alloc] initWithFilePath:self.filePath filterType:self.type];
    [self.dataSource refresh];
    self.tableView.dataSource = self.dataSource;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 60, 0);
    self.tableView.rowHeight = 60.0f;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 30, 0);
    [self.tableView reloadData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.tableView = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(NSArray*)selectedFilePath{
    NSArray* selectedIndexs = [self.tableView indexPathsForSelectedRows];
    return [self.dataSource objectsForIndexPaths:selectedIndexs];
}

#pragma mark - table vie delegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    FileItem* item = [self.dataSource objectAtIndexPath:indexPath];
    if ([[item.attributes fileType] isEqualToString:NSFileTypeDirectory]){
        FilePickerContentController* controller = [[FilePickerContentController alloc] initWithFilePath:item.filePath filterType:self.type];
        [self.navigationController pushViewController:controller animated:YES];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - button action
-(void)doneButtonClicked:(id)sender{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_PICKERCONTENT_DONE object:nil];
}

-(void)cancelButtonClicked:(id)sender{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_PICKERCONTENT_CANCEL object:nil];
}

@end
