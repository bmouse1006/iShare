//
//  ISSkydriveViewController.m
//  iShare
//
//  Created by Jin Jin on 12-8-26.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISSkydriveViewController.h"
#import "ISSkydriveDataSource.h"

@interface ISSkydriveViewController ()

@property (nonatomic, strong) LiveConnectClient* liveClient;
@property (nonatomic, strong) LiveConnectSession* session;

@end

@implementation ISSkydriveViewController

static NSString* LiveScope = @"wl.signin wl.basic";

- (id)initWithWorkingPath:(NSString *)workingPath
{
    self = [super initWithWorkingPath:workingPath];
    if (self) {
        [self configureLiveClientWithScopes:LiveScope];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.title = ([self.workingPath isEqualToDropboxPath:@"/"])?@"Dropbox":[self.workingPath lastPathComponent];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(ISShareServiceBaseDataSource*)createModel{
    return [[ISSkydriveDataSource alloc] initWithWorkingPath:self.workingPath];
}

- (void) configureLiveClientWithScopes:(NSString *)scopeText
{
    static NSString* CLIENT_ID = @"00000000400D564D";
    
    self.liveClient = [[LiveConnectClient alloc] initWithClientId:CLIENT_ID
                                                            scopes:[scopeText componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                                                          delegate:self
                                                        userState:@"init"];
}

#pragma mark - alert view delegate
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
/*    switch (alertView.tag) {
        case kDropboxAuthFailedAlertViewTag:
            [self autherizeFailed];
            break;
        default:
            break;
    }*/
}

#pragma mark - override super class
-(BOOL)serviceAutherized{
    return self.session != nil;
}

-(void)autherizeService{
    [self.liveClient login:self delegate:self userState:@"login"];
}

-(void)deleteFileAtPath:(NSString *)filePath{
    [self.liveClient deleteWithPath:filePath delegate:self];
}

-(void)createNewFolder:(NSString *)folderName{
//    self.liveClient 
//    [self.dbClient cancelAllRequests];
//    self.dbClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
//    self.dbClient.delegate = self;
//    [self.dbClient createFolder:[self.workingPath stringByAppendingPathComponent:folderName]];
}

-(void)downloadRemoteFile:(NSString*)remotePath toFolder:(NSString*)folder{
    
}

#pragma mark - live auth delegate
// This is invoked when the original method call is considered successful.
- (void) authCompleted: (LiveConnectSessionStatus) status
               session: (LiveConnectSession *) session
             userState: (id) userState{
    DebugLog(@"auth done");
    self.session = session;
}

-(void)authFailed:(NSError *)error userState:(id)userState{
    DebugLog(@"error is %@", [error localizedDescription]);
}

#pragma mark - operation delegate
// This is invoked when the operation was successful.
- (void) liveOperationSucceeded:(LiveOperation *)operation{
    DebugLog(@"operation succeeded");
    if ([operation.method isEqualToString:@"DELETE"]){
        [self deleteFinished];
    }
}

// This is invoked when the operation failed.
- (void) liveOperationFailed:(NSError *)error
                   operation:(LiveOperation*)operation{
    DebugLog(@"operation failed");
    if ([operation.method isEqualToString:@"DELETE"]){
        [self deleteFailed:error];
    }
}

@end
