//
//  ISGoogleDriveViewController.m
//  iShare
//
//  Created by Jin Jin on 12-11-28.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISGoogleDriveViewController.h"
#import "ISGoogleDriveDataSource.h"
#import "GTLDrive.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "ISGoogleAuth2ViewController.h"
#import "SVProgressHUD.h"
#import "FileItem.h"

#define kGDriveDownloadAlertViewTag 234

static NSString *const kKeychainItemName = @"Superb Share Google Drive";

//#if TARGET_IPHONE_SIMULATOR
//client ID for simulator
static NSString *const kClientID = @"568917835566-1str12to14o92h6q0efjsu2cho4g7sq0.apps.googleusercontent.com";
static NSString *const kClientSecret = @"JxgIF3Hi_Ot8eCioZrmQLHrN";
//#elif TARGET_OS_IPHONE
//client ID for device
//static NSString *const kClientID = @"568917835566.apps.googleusercontent.com";
//static NSString *const kClientSecret = @"0hiTKsfO6EIguEojJBjk3ibR";
//#endif

@interface ISGoogleDriveViewController ()

@property (nonatomic, strong) GTLServiceDrive* driveService;
@property (nonatomic, strong) GTLServiceTicket* ticket;
@property (nonatomic, strong) NSMutableSet* uploadTickets;
@property (nonatomic, strong) NSURLConnection* connection;
@property (nonatomic, strong) NSOutputStream* outputStream;

@end

@implementation ISGoogleDriveViewController

+(void)removeAutherize{
    GTMOAuth2Authentication* auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                                                          clientID:kClientID
                                                                                      clientSecret:kClientSecret];
    [GTMOAuth2ViewControllerTouch revokeTokenForGoogleAuthentication:auth];
    [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kKeychainItemName];
}

+(BOOL)canAutherize{
    return [self authenticatoin].canAuthorize;
}

+(GTMOAuth2Authentication*)authenticatoin{
    return [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                                 clientID:kClientID
                                                             clientSecret:kClientSecret];
}

-(GTLServiceDrive*)createDriveService{
    GTLServiceDrive* driveSerice = [[GTLServiceDrive alloc] init];
    driveSerice.authorizer = [[self class] authenticatoin];
    //specify to fetch all result
    driveSerice.shouldFetchNextPages = YES;
    driveSerice.retryEnabled = YES;
    
    return driveSerice;
}

-(id)initWithWorkingPath:(NSString *)workingPath{
    self = [super initWithWorkingPath:workingPath];
    if (self){
        self.uploadTickets = [NSMutableSet set];
    }
    
    return self;
}

-(void)dealloc{
    //cancel url connection and close output stream before release self
    [((GTMOAuth2Authentication*)self.driveService.authorizer).refreshFetcher stopFetching];
    [self.connection cancel];
    [self.outputStream close];
    [self.ticket cancelTicket];
}

-(void)viewDidLoad{
    self.title = @"Google Drive";
    [super viewDidLoad];
}

// Creates the auth controller for authorizing access to Googel Drive.
- (GTMOAuth2ViewControllerTouch *)createAuthController
{
    GTMOAuth2ViewControllerTouch *authController;
    authController = [[ISGoogleAuth2ViewController alloc] initWithScope:kGTLAuthScopeDrive
                                                                clientID:kClientID
                                                            clientSecret:kClientSecret
                                                        keychainItemName:kKeychainItemName
                                                                delegate:self
                                                        finishedSelector:@selector(viewController:finishedWithAuth:error:)];
    return authController;
}

//auth finished callback
-(void)viewController:(GTMOAuth2ViewControllerTouch*)controller
     finishedWithAuth:(GTMOAuth2Authentication*)auth
                error:(NSError*)error{
    if (error == nil){
        self.driveService.authorizer = auth;
        [self startLoading];
    }else{
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"alert_message_authfailed", nil)
                                  duration:2.0f];
    }

    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - override super class
-(void)operationCancelled{
    //following operations could be cancelled:
    //delete, upload, download
    //stop downloading
    [((GTMOAuth2Authentication*)self.driveService.authorizer).refreshFetcher stopFetching];
    [self.connection cancel];
    //stop deleting and creating
    [self.ticket cancelTicket];
    //stop uploading
    [self.uploadTickets makeObjectsPerformSelector:@selector(cancelTicket)];
}

-(ISShareServiceBaseDataSource*)createModel{

    self.driveService = [self createDriveService];
    
    ISGoogleDriveDataSource* datasource = [[ISGoogleDriveDataSource alloc] initWithWorkingPath:self.workingPath];
    datasource.driveSerivce = self.driveService;
    
    return datasource;
}

-(BOOL)serviceAutherized{
    return ((GTMOAuth2Authentication*)self.driveService.authorizer).canAuthorize;
}

-(void)autherizeService{
    GTMOAuth2ViewControllerTouch* controller = [self createAuthController];
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:controller]
                       animated:YES
                     completion:NULL];
}

-(UIViewController*)controllerForChildFolder:(NSString *)folderPath{
    return [[ISGoogleDriveViewController alloc] initWithWorkingPath:folderPath];
}

-(void)deleteFileItems:(FileShareServiceItem*)item{
    GTLDriveFile* file = item.originalFileObject;
    GTLQueryDrive* query = [GTLQueryDrive queryForFilesDeleteWithFileId:file.identifier];
    
    [self.ticket cancelTicket];
    self.ticket = [self.driveService executeQuery:query
                                completionHandler:^(GTLServiceTicket* ticket, id object, NSError* error){
                                    if (error){
                                        //error happened, notify
                                        [self deleteFailed:error];
                                    }else{
                                        //delete done
                                        [self deleteFinished];
                                    }
                                }];
}

-(void)createNewFolder:(NSString *)folderName{
    //id of current folder is self.workingPath
    //create a folder in the current folder
    //1. create a file object with MIME type = @"application/vnd.google-apps.folder"
    GTLDriveFile* folderObject = [[GTLDriveFile alloc] init];
    folderObject.title = folderName;
    folderObject.mimeType = @"application/vnd.google-apps.folder";
    
    GTLDriveParentReference* parent = [[GTLDriveParentReference alloc] init];
    parent.identifier = self.workingPath;
    folderObject.parents = @[parent];
    
    //2. Get file insert query
    GTLQueryDrive* query = [GTLQueryDrive queryForFilesInsertWithObject:folderObject
                                                       uploadParameters:nil];
    //3. Execute query
    [self.ticket cancelTicket];
    self.ticket = [self.driveService executeQuery:query
                                completionHandler:^(GTLServiceTicket* ticket, id object, NSError* error){
                                    if (error){
                                        //notify error happend
                                        [self folderCreateFailed:error];
                                    }else{
                                        //notify create finished
                                        [self folderCreateFinished];
                                    }
                                }];
}

-(void)downloadRemoteFile:(FileShareServiceItem*)item
                 toFolder:(NSString*)folder{
    NSString* destinationFilepath = [folder stringByAppendingPathComponent:item.filename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:destinationFilepath]){
        self.downloadFileItem = item;
        self.downloadToFolder = folder;
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"alert_message_filealreadyexists", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"btn_title_cancel", nil)
                                              otherButtonTitles:NSLocalizedString(@"btn_title_confirm", nil), nil];
        alert.tag = kGDriveDownloadAlertViewTag;
        [alert show];
    }else{
        [self downloadGDriveFile:item
                        toFolder:folder
                    needOverride:NO];
    }
}

-(void)downloadGDriveFile:(FileShareServiceItem*)fileItem
                 toFolder:(NSString*)folderPath
             needOverride:(BOOL)needOverride{
    
    NSString* destinationFile = [folderPath stringByAppendingPathComponent:fileItem.filename];
    if (needOverride){
        [[NSFileManager defaultManager] removeItemAtPath:destinationFile error:NULL];
    }else if ([[NSFileManager defaultManager] fileExistsAtPath:destinationFile]){
        [self userDismissedHUD:nil];
        return;
    }
    BOOL isPDF = NO;
    //create download file query
    GTLDriveFile* file = fileItem.originalFileObject;
    NSString* downloadString = nil;
    
    if (file.downloadUrl){
        //normal file
        downloadString = file.downloadUrl;
    }else if (file.webContentLink){
        //link a user to a file
        downloadString = file.webContentLink;
    }else{
        //link for google doc
        downloadString = [file.exportLinks additionalPropertyForName:@"application/pdf"];
        isPDF = YES;
    }
    
    if (downloadString){
        NSURL* downloadURL = [NSURL URLWithString:downloadString];
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:downloadURL];
        [[[self class] authenticatoin] authorizeRequest:request
                                      completionHandler:^(NSError* error){
                                          //create output stream
                                          //close output stream if any
                                          [self.outputStream close];
                                          //create output stream
                                          //1. create destination filePath
                                          NSString* filePath = [folderPath stringByAppendingPathComponent:fileItem.filename];
                                          if (isPDF){
                                              filePath = [filePath stringByAppendingPathExtension:@"pdf"];
                                          }
                                          //2. create output stream
                                          self.outputStream = [[NSOutputStream alloc] initToFileAtPath:filePath append:NO];
                                          //ready to receive data
                                          [self.outputStream open];
                                          self.connection = [NSURLConnection connectionWithRequest:request
                                                                                          delegate:self];
                                          [self.connection start];
        }];
    }
}

-(void)uploadSelectedFiles:(NSArray *)selectedFiles{
    
    [selectedFiles enumerateObjectsUsingBlock:^(FileItem* fileItem, NSUInteger idx, BOOL* stop){
        //create file object
        GTLDriveFile* file = [[GTLDriveFile alloc] init];
        file.title = [fileItem.filePath lastPathComponent];
        //create parent reference
        GTLDriveParentReference* parentReference = [[GTLDriveParentReference alloc] init];
        parentReference.identifier = self.workingPath;
        file.parents = @[parentReference];
        //create file handler
        NSFileHandle* fileHandler = [NSFileHandle fileHandleForReadingAtPath:fileItem.filePath];
        //create file object parameters
        GTLUploadParameters* parameters = [GTLUploadParameters uploadParametersWithFileHandle:fileHandler
                                                                                     MIMEType:nil];
        //create file insert query
        GTLQueryDrive* query = [GTLQueryDrive queryForFilesInsertWithObject:file
                                                           uploadParameters:parameters];
        
        [[self serviceLock] lock];
        GTLServiceTicket* ticket = [self.driveService executeQuery:query
                                                 completionHandler:^(GTLServiceTicket* ticket, id object, NSError* error){
                                                     //upload finished, remove the ticket
                                                     [[self serviceLock] lock];
                                                     [self.uploadTickets removeObject:ticket];
                                                     if ([self.uploadTickets count] == 0){
                                                         //all upload finished
                                                         if (error){
                                                             [self uploadFailed:error];
                                                         }else{
                                                             [self uploadFinished];
                                                         }
                                                     }
                                                     [[self serviceLock] unlock];
                                                 }];
        [self.uploadTickets addObject:ticket];
        
        [[self serviceLock] unlock];
        
    }];
}

-(NSLock*)serviceLock{
    static NSLock* _lock = nil;
    if (_lock == nil){
        _lock = [[NSLock alloc] init];
    }
    
    return _lock;
}

#pragma mark - alert view delegate
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    switch (alertView.tag) {
        case kGDriveDownloadAlertViewTag:
            [self downloadGDriveFile:self.downloadFileItem
                            toFolder:self.downloadToFolder
                        needOverride:(buttonIndex == 1)];
            break;
        default:
            break;
    }
}

#pragma mark - connection data delegate

static long long ExpectedLength = 0.0f;
static long long ReceivedLength = 0.0f;

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    //caculate length of response
    ExpectedLength = response.expectedContentLength;
    ReceivedLength = 0.0f;
    if (ExpectedLength != NSURLResponseUnknownLength){
        [SVProgressHUD showWithStatus:NSLocalizedString(@"progress_message_havedownloaded", nil)
                             maskType:SVProgressHUDMaskTypeGradient];
    }
}

-(void)connection:(NSURLConnection *)connection
   didReceiveData:(NSData *)data{
    DebugLog(@"did received data");
    ReceivedLength += [data length];
    
    if (ExpectedLength != NSURLResponseUnknownLength){
        [self downloadFinishedWithProgress:((float)ReceivedLength)/((float)ExpectedLength)];
    }
    
    [self.outputStream write:[data bytes] maxLength:[data length]];
}

-(void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite{
    DebugLog(@"");
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    //download finished
    DebugLog(@"download finished");
    //close stream
    [self.outputStream close];
    //notify download finished
    [self downloadFinished];
}

@end
