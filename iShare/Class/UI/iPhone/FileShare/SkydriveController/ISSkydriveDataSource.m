//
//  ISSkydriveDataSource.m
//  iShare
//
//  Created by Jin Jin on 12-9-1.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISSkydriveDataSource.h"

@implementation ISSkydriveDataSource

-(void)dealloc{
}

-(id)initWithWorkingPath:(NSString*)workingPath{
    self = [super init];
    if (self){
//        self.workingPath = (workingPath.length > 0)?workingPath:kDBRootDropbox;
    }
    
    return self;
}

-(void)loadContent{
//    [self.dbClient cancelAllRequests];
//    self.dbClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
//    self.dbClient.delegate = self;
//    [self.dbClient loadMetadata:self.workingPath withHash:self.workingHash];
}

@end
