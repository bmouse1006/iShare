//
//  FileOperationWrap.h
//  iShare
//
//  Created by Jin Jin on 12-8-8.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RARExtractException.h"

typedef void(^FileOperationCompletionBlock)(BOOL);

typedef enum{
    FileContentTypeDirectory = 1 << 0,
    FileContentTypeImage = 1 << 1,
    FileContentTypeAppleMovie = 1 << 2,
    FileContentTypeMusic = 1 << 3,
    FileContentTypeText = 1 << 4,
    FileContentTypePDF = 1 << 5,
    FileContentTypeDocument = 1 << 6,
    FileContentTypeZip = 1 << 7,
    FileContentTypeSourceCode = 1 << 8,
    FileContentTypeRAR = 1 << 9,
    FileContentType7Zip = 1 << 10,
    FileContentTypeOther = 1 << 14,
    FileContentTypeAll = (1 << 15) - 1
} FileContentType;

@interface FileOperationWrap : NSObject

+(id)sharedWrap;

-(void)removeFileItems:(NSArray*)fileItems withCompletionBlock:(FileOperationCompletionBlock)block;

-(UIImage*)thumbnailForFile:(NSString*)filePath previewEnabled:(BOOL)previewEnabled;
-(NSString*)thumbnailNameForFile:(NSString*)filePath;

-(BOOL)createDirectoryWithName:(NSString*)name path:(NSString*)path;
-(BOOL)createFileWithName:(NSString*)name path:(NSString*)path;
-(BOOL)saveFile:(NSData*)fileData withName:(NSString*)name path:(NSString*)path;

-(NSArray*)allImagePathsInFolder:(NSString*)folder;
-(NSArray*)allFilesWithFileContentType:(FileContentType)type inFolder:(NSString*)folder;

-(NSString*)zipFileAtFilePath:(NSString*)filePath toPath:(NSString*)path;
-(BOOL)isEncryptedZipFile:(NSString*)filePath;
-(BOOL)unzipFileAtFilePath:(NSString*)filePath
                    toPath:(NSString*)path
              withPassword:(NSString*)password;
-(BOOL)unrarFileAtFilePath:(NSString*)filePath
                  toFolder:(NSString*)folderPath
              withPassword:(NSString*)password;

-(NSString*)validFilePathForFilename:(NSString*)filename atPath:(NSString*)path;
-(NSString*)homePath;
-(NSString*)tempFolder;

-(FileContentType)fileTypeWithFilePath:(NSString*)filePath;

-(void)openFileItemAtPath:(NSString*)filePath withController:(UIViewController*)controller;
-(void)clearTempFolder;

-(NSString*)normalizedSize:(long long)size;

@end
