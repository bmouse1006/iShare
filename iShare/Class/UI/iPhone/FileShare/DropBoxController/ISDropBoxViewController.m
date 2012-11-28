//
//  ISDropBoxViewController.m
//  iShare
//
//  Created by Jin Jin on 12-8-26.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISDropBoxViewController.h"
#import "ISDropBoxDataSource.h"
#import "FileItem.h"

#define kDropboxAuthFailedAlertViewTag 100
#define kDropboxDownloadAlertViewTag 200

@interface ISDropBoxViewController (){
    BOOL _isAutherizing;
    NSUInteger _uploadFileCount;
}

@property (nonatomic, strong) DBRestClient* dbClient;
@property (nonatomic, strong) NSMutableArray* uploadDbClients;

@end

@implementation ISDropBoxViewController

- (id)initWithWorkingPath:(NSString *)workingPath
{
    self = [super initWithWorkingPath:workingPath];
    if (self) {
        // Custom initialization
        [self setupDropboxSession];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = ([self.workingPath isEqualToDropboxPath:@"/"])?@"Dropbox":[self.workingPath lastPathComponent];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)viewDidAppear:(BOOL)animated{
    if (_isAutherizing){
        [self startLoading];
        _isAutherizing = NO;
    }
    
    [super viewDidAppear:animated];
}

-(ISShareServiceBaseDataSource*)createModel{
    return [[ISDropBoxDataSource alloc] initWithWorkingPath:self.workingPath];
}

-(void)setupDropboxSession{
    [DBSession sharedSession].delegate = self;
}

#pragma mark - dropbox delegate
- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId{
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"alert_message_dropboxauthfailed", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"btn_title_cancel", nil) otherButtonTitles:nil];
    alertView.tag = kDropboxAuthFailedAlertViewTag;
    [alertView show];
}

-(void)restClient:(DBRestClient *)client createdFolder:(DBMetadata *)folder{
    [self folderCreateFinished];
}

-(void)restClient:(DBRestClient *)client createFolderFailedWithError:(NSError *)error{
    [self folderCreateFailed:error];
}

- (void)restClient:(DBRestClient*)client deletedPath:(NSString *)path{
    [self deleteFinished];
}

- (void)restClient:(DBRestClient*)client deletePathFailedWithError:(NSError*)error{
    [self deleteFailed:error];
}

-(void)restClient:(DBRestClient *)client loadedFile:(NSString *)destPath{
    [self downloadFinished];
}

-(void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error{
    [self downloadFailed:error];
}

-(void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath{
    NSLock* locker = [self uploadLock];
    [locker lock];
    
    client.delegate = nil;
    _uploadFileCount -= 1;
    if (_uploadFileCount == 0){
        //all upload finished
        [self uploadFinished];
    }
    
    [locker unlock];
}

-(void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error{

}

-(NSLock*)uploadLock{
    static NSLock* lock = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lock = [[NSLock alloc] init];
    });
    
    return lock;
}

#pragma mark - alert view delegate
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    switch (alertView.tag) {
        case kDropboxAuthFailedAlertViewTag:
            [self autherizeFailed];
            break;
        case kDropboxDownloadAlertViewTag:
            [self downloadDropboxFile:self.downloadFilepath toFolder:self.downloadToFolder needOverride:(buttonIndex == 1)];
            break;
        default:
            break;
    }
}

#pragma mark - override super class
-(BOOL)serviceAutherized{
    return [[DBSession sharedSession] isLinked];
}

-(void)autherizeService{
    _isAutherizing = YES;
    [[DBSession sharedSession] linkFromController:self];
}

-(UIViewController*)controllerForChildFolder:(NSString *)folderPath{
    return [[ISDropBoxViewController alloc] initWithWorkingPath:folderPath];
}

-(void)deleteFileAtPath:(NSString *)filePath{
    [self.dbClient cancelAllRequests];
    self.dbClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    self.dbClient.delegate = self;
    [self.dbClient deletePath:filePath];
}

-(void)createNewFolder:(NSString *)folderName{
    [self.dbClient cancelAllRequests];
    self.dbClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    self.dbClient.delegate = self;
    [self.dbClient createFolder:[self.workingPath stringByAppendingPathComponent:folderName]];
}

-(void)downloadRemoteFile:(NSString*)remotePath toFolder:(NSString*)folder{
    NSString* destinationFilepath = [folder stringByAppendingPathComponent:[remotePath lastPathComponent]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:destinationFilepath]){
        self.downloadFilepath = remotePath;
        self.downloadToFolder = folder;
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"alert_message_filealreadyexists", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"btn_title_cancel", nil) otherButtonTitles:NSLocalizedString(@"btn_title_confirm", nil), nil];
        alert.tag = kDropboxDownloadAlertViewTag;
        [alert show];
    }else{
        [self downloadDropboxFile:remotePath toFolder:folder needOverride:NO];
    }
}

-(void)downloadDropboxFile:(NSString*)dropboxFilepath toFolder:(NSString*)folder needOverride:(BOOL)needOverride{
    NSString* destinationFile = [folder stringByAppendingPathComponent:[dropboxFilepath lastPathComponent]];
    if (needOverride){
        [[NSFileManager defaultManager] removeItemAtPath:destinationFile error:NULL];
    }else if ([[NSFileManager defaultManager] fileExistsAtPath:destinationFile]){
        [self downloadFinished];
        return;
    }
    
    [self.dbClient cancelAllRequests];
    self.dbClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    self.dbClient.delegate = self;
    [self.dbClient loadFile:dropboxFilepath intoPath:destinationFile];
}

-(void)uploadSelectedFiles:(NSArray *)selectedFiles{
    self.uploadDbClients = [NSMutableArray array];
    _uploadFileCount = [selectedFiles count];
    
    
    for (FileItem* fileItem in selectedFiles){
        DBRestClient* restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        restClient.delegate = self;
        [self.uploadDbClients addObject:restClient];
        [restClient uploadFile:[fileItem.filePath lastPathComponent] toPath:self.workingPath withParentRev:nil fromPath:fileItem.filePath];
    }
}

@end
