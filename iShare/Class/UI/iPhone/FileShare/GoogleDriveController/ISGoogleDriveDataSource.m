//
//  ISGoogleDriveDataSource.m
//  iShare
//
//  Created by Jin Jin on 12-11-28.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISGoogleDriveDataSource.h"
#import "GTLDriveFileList.h"

@implementation ISGoogleDriveDataSource

-(void)loadContent{
    DebugLog(@"start loading google drive content");
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesList];
    NSString* search = @"trashed=false";
    if (self.workingPath.length > 0){
        search = [search stringByAppendingFormat:@" and '%@' in parents", self.workingPath];
    }
    query.q = search;
    //specify the fields
//    query.fields = @"kind,etag,items(id,downloadUrl,editable,etag,exportLinks,kind,labels,originalFilename,title, mimeType, fileExtension)";
    //application/vnd.google-apps.folder
    [self.driveSerivce executeQuery:query completionHandler:^(GTLServiceTicket* ticket, GTLDriveFileList* fileList, NSError* error){
        NSMutableArray* items = [NSMutableArray array];
        
        [fileList.items enumerateObjectsUsingBlock:^(GTLDriveFile* file, NSUInteger idx, BOOL* stop){
            FileShareServiceItem* item = [[FileShareServiceItem alloc] init];
            item.serviceType = FileShareServiceTypeGDrive;
            item.filePath = (file.downloadUrl)?file.downloadUrl:file.identifier;
            item.originalFileName = (file.originalFilename)?file.originalFilename:file.title;
            item.isDirectory = [file.mimeType isEqualToString:@"application/vnd.google-apps.folder"];
            
            [items addObject:item];
            
        }];

        self.items = items;
        [self finishLoading];
    }];
}

@end
