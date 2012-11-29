//
//  ISGoogleDriveDataSource.m
//  iShare
//
//  Created by Jin Jin on 12-11-28.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISGoogleDriveDataSource.h"

@implementation ISGoogleDriveDataSource

-(void)loadContent{
    DebugLog(@"start loading google drive content");
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesList];

    [self.driveSerivce executeQuery:query completionHandler:^(GTLServiceTicket* ticket, id object, NSError* error){
        DebugLog(@"load finished");
    }];
}

@end
