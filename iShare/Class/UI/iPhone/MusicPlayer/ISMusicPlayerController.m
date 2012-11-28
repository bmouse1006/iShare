//
//  ISMusicPlayerController.m
//  iShare
//
//  Created by Jin Jin on 12-8-3.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISMusicPlayerController.h"
#import "MDAudioPlayerController.h"
#import "JJAudioPlayerManager.h"
#import "FilePickerViewController.h"
#import "MDAudioFile.h"
#import "FileItem.h"

@interface ISMusicPlayerController ()

@property (nonatomic, strong) NSMutableArray* playList;

@end

@implementation ISMusicPlayerController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = NSLocalizedString(@"tab_title_music", nil);
        self.tabBarItem.title = NSLocalizedString(@"tab_title_music", nil);
        self.tabBarItem.image = [UIImage imageNamed:@"ic_tab_music"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UIImage* normalImage = [UIImage imageNamed:@"btn_title_bar_next"];
    UIImage* selectedImage = [UIImage imageNamed:@"btn_title_bar_next_pressed"];
    normalImage = [normalImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 4, 0, 13)];
    selectedImage = [selectedImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 4, 0, 13)];
    [self.nowPlayingButton setBackgroundImage:normalImage forState:UIControlStateNormal];
    [self.nowPlayingButton setBackgroundImage:selectedImage forState:UIControlStateSelected];
    [self.nowPlayingButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 5)];
    [self.nowPlayingButton setTitle:NSLocalizedString(@"btn_title_nowplaying", nil) forState:UIControlStateNormal];
    
    self.addSongCellLabel.text = NSLocalizedString(@"cell_title_addsong", nil);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if ([[JJAudioPlayerManager sharedManager].currentPlayer isPlaying]){
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.nowPlayingButton];
    }else{
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    [self refresh];
    [self.tableView reloadData];
}

#pragma mark - action
-(IBAction)nowPlayingButtonIsClicked:(id)sender{
    
    MDAudioPlayerController* musicPlayer = [[MDAudioPlayerController alloc] initWithAudioPlayerManager:[JJAudioPlayerManager sharedManager]];
    
    [self.navigationController pushViewController:musicPlayer animated:YES];
}

#pragma mark - delegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0){
        //add new song
        FilePickerViewController* pickerViewController = [[FilePickerViewController alloc] initWithFilePath:nil filterType:FileContentTypeMusic|FileContentTypeDirectory];
        
        JJAudioPlayerManager* manager = [JJAudioPlayerManager sharedManager];
        pickerViewController.completionBlock = ^(NSArray* fileList){
            [fileList enumerateObjectsUsingBlock:^(FileItem* fileItem, NSUInteger idx, BOOL* stop){
                MDAudioFile* audioFile = [[MDAudioFile alloc] initWithPath:[NSURL fileURLWithPath:fileItem.filePath]];
                [manager addToDefaultPlayList:audioFile playNow:NO];
            }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self refresh];
                [self.tableView reloadData];
            });
            [self dismissViewControllerAnimated:YES completion:NULL];
        };
        
        pickerViewController.cancellationBlock = ^{
            [self dismissViewControllerAnimated:YES completion:NULL];
        };
        
        [self presentModalViewController:pickerViewController animated:YES];
        
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    }else if(indexPath.section == 1){
        MDAudioFile* audioFile = [self.playList objectAtIndex:indexPath.row];
        JJAudioPlayerManager* manager = [JJAudioPlayerManager sharedManager];
        [manager addToDefaultPlayList:audioFile playNow:YES];
        MDAudioPlayerController* playerController = [[MDAudioPlayerController alloc] initWithAudioPlayerManager:manager];
        
        [self.navigationController pushViewController:playerController animated:YES];
    }
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 1){//playlist section
        if (editingStyle == UITableViewCellEditingStyleDelete){
            MDAudioFile* audioFile = [self.playList objectAtIndex:indexPath.row];
            [[JJAudioPlayerManager sharedManager] removeAudioFilFromPlayList:audioFile];
            [self refresh];
            
            [self.tableView beginUpdates];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
            [self.tableView endUpdates];
        }
    }
}

-(NSString*)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath{
    return NSLocalizedString(@"cell_title_removefromplaylist", nil);
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0){
        return NO;
    }else if (indexPath.section == 1){
        return YES;
    }
    
    return NO;
}

#pragma mark - datasource
-(void)refresh{
    NSArray* songs = [[JJAudioPlayerManager sharedManager] defaultList];
    [songs enumerateObjectsUsingBlock:^(MDAudioFile* audioFile, NSUInteger idx, BOOL* stop){
        if ([[NSFileManager defaultManager] fileExistsAtPath:[audioFile.filePath path]] == NO){
            [[JJAudioPlayerManager sharedManager] removeAudioFilFromPlayList:audioFile];
        }
    }];
    self.playList = [NSMutableArray arrayWithArray:[[JJAudioPlayerManager sharedManager] defaultList]];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section == 0){
        return 1;
    }else if (section == 1){
        return [self.playList count];
    }
    
    return 0;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0){
        //cell to add song
        return self.addSongCell;
    }else if (indexPath.section == 1){
        static NSString* SongCellIdentifier = @"SongCellIdentifier";
        
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:SongCellIdentifier];
        
        if (cell == nil){
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:SongCellIdentifier];
        }
        
        MDAudioFile* audioFile = [self.playList objectAtIndex:indexPath.row];
        
        cell.textLabel.text = [audioFile title];
        cell.detailTextLabel.text = [audioFile artist];
        cell.imageView.image = [audioFile coverImage];
        
        return cell;
    }
    
    return nil;
}

@end
