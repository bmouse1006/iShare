//
//  ISDropBoxDataSource.m
//  iShare
//
//  Created by Jin Jin on 12-8-27.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISDropBoxDataSource.h"
#import "FileShareServiceItem.h"

@interface ISDropBoxDataSource ()

@property (nonatomic, strong) DBRestClient* dbClient;
@property (nonatomic, strong) NSString* workingHash;

@end

@implementation ISDropBoxDataSource

-(void)dealloc{
    [self.dbClient cancelAllRequests];
    self.dbClient.delegate = nil;
}

-(id)initWithWorkingPath:(NSString*)workingPath{
    self = [super initWithWorkingPath:workingPath];
    if (self){
        self.workingPath = (workingPath.length > 0)?workingPath:kDBRootDropbox;
    }
    
    return self;
}

-(void)loadContent{
    [self.dbClient cancelAllRequests];
    self.dbClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    self.dbClient.delegate = self;
    [self.dbClient loadMetadata:self.workingPath withHash:self.workingHash];
}

#pragma mark - dropbox rest client delegate
- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata {
    self.workingHash = metadata.hash;
    
    NSMutableArray* items = [NSMutableArray array];
    [metadata.contents enumerateObjectsUsingBlock:^(DBMetadata* child, NSUInteger idx, BOOL* stop){
        FileShareServiceItem* item = [[FileShareServiceItem alloc] init];
        item.serviceType = FileShareServiceTypeDropBox;
        item.filePath = child.path;
        item.isDirectory = child.isDirectory;
        [items addObject:item];
    }];

    self.items = items;
    
    [self finishLoading];
}

- (void)restClient:(DBRestClient*)client metadataUnchangedAtPath:(NSString*)path {
    [self finishLoading];
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error {
    NSLog(@"restClient:loadMetadataFailedWithError: %@", [error localizedDescription]);
    [self failedLoading:error];
}

@end
