//
//  ISHTTPConnection.m
//  iShare
//
//  Created by Jin Jin on 12-9-19.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISHTTPConnection.h"
#import "HTTPMessage.h"
#import "MultipartMessageHeader.h"
#import "MultipartMessageHeaderField.h"
#import "MultipartFormDataParser.h"
#import "HTTPDynamicFileResponse.h"
#import "HTTPDataResponse.h"
#import "HTTPFileResponse.h"
#import "ISHTTPDownloadResponse.h"
#import "FileOperationWrap.h"
#import "NSDictionary+FileOperationWrap.h"

#define kFileUploadRequestPath @"/qqfile="

typedef enum {
    PostMethodTypeUploadFile,
    PostMethodTypeFileOperation
} PostMethodType;

@interface ISHTTPConnection(){
    BOOL _uploadFinished;
}

@property (nonatomic, strong) MultipartFormDataParser* parser;
@property (nonatomic, strong) NSFileHandle*	storeFile;
@property (nonatomic, strong) NSMutableArray* uploadedFiles;
@property (nonatomic, strong) NSMutableData* cacheData;

@property (nonatomic, assign) PostMethodType postType;
//@property (nonatomic, assign) CFWriteStreamRef writeStream;
@property (nonatomic, retain) NSOutputStream* writeStream;

@end

@implementation ISHTTPConnection

static NSString* CurrentFilePath = @"";

//connection auth
-(BOOL)isPasswordProtected:(NSString *)path{
    return [ISUserPreferenceDefine HttpShareAuthEnabled];
}

- (BOOL)useDigestAccessAuthentication
{
	
	// Digest access authentication is the default setting.
	// Notice in Safari that when you're prompted for your password,
	// Safari tells you "Your login information will be sent securely."
	//
	// If you return NO in this method, the HTTP server will use
	// basic authentication. Try it and you'll see that Safari
	// will tell you "Your password will be sent unencrypted",
	// which is strongly discouraged.
	
	return YES;
}

-(NSString*)passwordForUser:(NSString *)username{
    if ([username isEqualToString:[ISUserPreferenceDefine httpShareUsername]]){
        return [ISUserPreferenceDefine httpSharePassword];
    }else{
        return nil;
    }
}

//upload support
- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
	// Add support for POST
	
	if ([method isEqualToString:@"POST"])
	{
        return YES;
	}
	
	return [super supportsMethod:method atPath:path];
}


- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path
{	
	// Inform HTTP server that we expect a body to accompany a POST request
//	
	if([method isEqualToString:@"POST"]) {
        NSString* contentType = [request headerField:@"Content-Type"];
        if ([contentType isEqualToString:@"application/x-www-form-urlencoded"]){
            //delete or rename or ...
            self.postType = PostMethodTypeFileOperation;
        }else if ([contentType isEqualToString:@"application/octet-stream"]){
            //uploading file
            self.postType = PostMethodTypeUploadFile;
        }
    }
	return [super expectsRequestBodyFromMethod:method atPath:path];
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	if ([method isEqualToString:@"POST"])
	{
        //重新刷新index？
        if (self.postType == PostMethodTypeFileOperation){
            return [self indexResponseWithFilepath:[[FileOperationWrap homePath] stringByAppendingPathComponent:CurrentFilePath]];
        }else if (self.postType == PostMethodTypeUploadFile){
            NSString* responseFilePath = [[NSBundle mainBundle] pathForResource:@"UploadResponse" ofType:nil];
            return [[HTTPFileResponse alloc] initWithFilePath:responseFilePath forConnection:self];
        }
	}
	if( [method isEqualToString:@"GET"]) {
        //如果文件存在，就下载文件
        NSString* filePath = [[FileOperationWrap homePath] stringByAppendingPathComponent:path];
        BOOL isDir;
        BOOL itemExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir];
        if (itemExists && !isDir){
            //存在该文件，则下载
            // let download the uploaded files
            return [[ISHTTPDownloadResponse alloc] initWithFilePath:filePath forConnection:self];
        }else if (itemExists && isDir){
            //存在该目录，则返回显示了该目录文件结构的index
            CurrentFilePath = path;
            return [self indexResponseWithFilepath:filePath];
        }
	}
	
	return [super httpResponseForMethod:method URI:path];
}

- (void)prepareForBodyWithSize:(UInt64)contentLength{
    if (self.postType == PostMethodTypeUploadFile){
        _uploadFinished = NO;
        //open stream
        NSString* filename = [[request headerField:@"X-File-Name"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString* validFilePath = [FileOperationWrap validFilePathForFilename:filename atPath:[[FileOperationWrap homePath] stringByAppendingPathComponent:CurrentFilePath]];
        [self createWriteStreamWithFilePath:validFilePath];
    }else{
        self.cacheData = [NSMutableData dataWithCapacity:contentLength];   
    }
}

- (void)processBodyData:(NSData *)postDataChunk
{
    if (self.postType == PostMethodTypeUploadFile){
        //write stream
        [self writeStreamWithData:postDataChunk];
    }else{
        [self.cacheData appendData:postDataChunk];
    }
}

-(void)finishBody{
    //write to file
    NSLog(@"file upload finished");
    
    NSString* fullPath = [[FileOperationWrap homePath] stringByAppendingPathComponent:CurrentFilePath];
    
    [[self fileLock] lock];
    
    if (self.postType == PostMethodTypeUploadFile){
        
        [self closeStream];
        self.cacheData = nil;
        
        _uploadFinished = YES;
    }else if (self.postType == PostMethodTypeFileOperation){
        NSString* formString = [[NSString alloc] initWithData:self.cacheData encoding:NSUTF8StringEncoding];
        NSDictionary* paramters = [self parametersFromFormString:formString];
        NSString* operation = [paramters objectForKey:@"operationType"];
        NSString* originalName = [paramters objectForKey:@"originalItem"];
        NSString* targetName = [paramters objectForKey:@"targetItem"];
//        NSString
        NSString* originalPath = [fullPath stringByAppendingPathComponent:originalName];
        if ([operation isEqualToString:@"delete"]){
            //remove file
            NSError* error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:originalPath error:&error];
            if (error){
                NSLog(@"error happended: %@", [error localizedDescription]);
            }
        }else if ([operation isEqualToString:@"rename"]){
            //rename file
            [[NSFileManager defaultManager] moveItemAtPath:originalPath toPath:[FileOperationWrap validFilePathForFilename:targetName atPath:fullPath] error:NULL];
        }else if ([operation isEqualToString:@"create"]){
            //create folder
            [FileOperationWrap createDirectoryWithName:targetName path:fullPath];
        }
    }
    
    [[self fileLock] unlock];
}
                               
-(NSDictionary*)parametersFromFormString:(NSString*)formString{
    formString = [formString stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    NSArray* pairs = [formString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"&"]];
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    
    [pairs enumerateObjectsUsingBlock:^(NSString* pair, NSUInteger idx, BOOL* stop){
        NSArray* parameter = [pair componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"="]];
        if ([parameter count] == 2){
            [parameters setObject:[[parameter objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:[parameter objectAtIndex:0]];
        }
    }];
    
    return parameters;
}

-(NSLock*)fileLock{
    static NSLock* fileLock = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fileLock = [[NSLock alloc] init];
    });
    
    return fileLock;
}

-(HTTPDynamicFileResponse*)indexResponseWithFilepath:(NSString*)filepath{
    
    NSString* fileItemTemplate = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"fileItemTemplate" ofType:nil] usedEncoding:NULL error:NULL];
    NSString* folderItemTemplate = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"folderItemTemplate" ofType:nil] usedEncoding:NULL error:NULL];
    NSString* parentFolderTemplate = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"gotoparentdirTemplate" ofType:nil] usedEncoding:NULL error:NULL];
    
    NSFileManager* fm = [NSFileManager defaultManager];
    NSArray* filenames = [fm contentsOfDirectoryAtPath:filepath error:NULL];
    
    NSMutableString* fileItemsString = [NSMutableString string];
    NSMutableString* folderItemString = [NSMutableString string];
    
    for (NSString* filename in filenames){
        if ([filename hasPrefix:@"."]){
            //skip hidden files
            continue;
        }
        NSDictionary* attribute = [fm attributesOfItemAtPath:[filepath stringByAppendingPathComponent:filename] error:NULL];
        NSString* fileString = @"";
        if ([[attribute fileType] isEqualToString:NSFileTypeDirectory]){
            fileString = [folderItemTemplate stringByReplacingOccurrencesOfString:@"#FILENAME#" withString:[filename lastPathComponent]];
            fileString = [fileString stringByReplacingOccurrencesOfString:@"#FILEMODIFICATIONDATE#" withString:[attribute shortLocalizedModificationDate]];
            fileString = [fileString stringByReplacingOccurrencesOfString:@"#FILENAMEHREF#" withString:[CurrentFilePath stringByAppendingPathComponent:filename]];
            [folderItemString appendString:fileString];
        }else{
            fileString = [fileItemTemplate stringByReplacingOccurrencesOfString:@"#FILENAME#" withString:[filename lastPathComponent]];
            fileString = [fileString stringByReplacingOccurrencesOfString:@"#FILEMODIFICATIONDATE#" withString:[attribute shortLocalizedModificationDate]];
            fileString = [fileString stringByReplacingOccurrencesOfString:@"#FILESIZE#" withString:[NSString stringWithFormat:@"%@", [attribute normalizedFileSize]]];
            fileString = [fileString stringByReplacingOccurrencesOfString:@"#FILENAMEHREF#" withString:[CurrentFilePath stringByAppendingPathComponent:filename]];
            fileString = [fileString stringByReplacingOccurrencesOfString:@"#FILEICON#" withString:[[FileOperationWrap thumbnailNameForFile:filename] stringByAppendingPathExtension:@"png"]];
            [fileItemsString appendString:fileString];
        }
    }
    
    NSString* fileListString = [NSString stringWithFormat:@"%@%@", folderItemString, fileItemsString];
    NSString* deviceName = [[UIDevice currentDevice] name];
    
    if ([CurrentFilePath isEqualToString:@"/"]){
        parentFolderTemplate = @"";
    }
    
    return [[HTTPDynamicFileResponse alloc] initWithFilePath:[[config documentRoot] stringByAppendingPathComponent:@"index.html"]
                                               forConnection:self
                                                   separator:@"%%"
                                       replacementDictionary:@{@"FileItemLoop" : fileListString, @"DeviceName": deviceName, @"GotoParentDir": parentFolderTemplate}];
}

#pragma mark - stream methods

-(void)createWriteStreamWithFilePath:(NSString*)filePath{
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    self.writeStream = [NSOutputStream outputStreamToFileAtPath:filePath append:NO];
    [self.writeStream open];
}

-(void)writeStreamWithData:(NSData*)data{
    NSUInteger length = [data length];
    UInt8 *buff = (UInt8*)[data bytes];
    
    NSInteger writeLength = [self.writeStream write:buff maxLength:length];
    if (writeLength < 0){
//        NSError* error = [self.writeStream streamError];
        //report error
    }
}

-(void)closeStream{
    [self.writeStream close];
    self.writeStream = nil;
}

-(NSLock*)streamLock{
    static dispatch_once_t onceToken;
    static NSLock* streamLock = nil;
    dispatch_once(&onceToken, ^{
        streamLock = [[NSLock alloc] init];
    });
    
    return streamLock;
}

@end
