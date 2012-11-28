//
//  ISiCouldDataSource.m
//  iShare
//
//  Created by Jin Jin on 12-9-2.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISiCouldDataSource.h"

@implementation ISiCouldDataSource

-(void)loadContent{
    NSURL* url = [NSURL fileURLWithPath:self.workingPath];
    NSError* error = nil;
    NSArray* array = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:url includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
    
    NSMutableArray* items = [NSMutableArray array];
    [array enumerateObjectsUsingBlock:^(NSURL* filename, NSUInteger idx, BOOL* stop){
        NSString* filePath = [filename path];

        FileShareServiceItem* item = [[FileShareServiceItem alloc] init];
        item.serviceType = FileShareServiceTypeiCloud;
        item.filePath = filePath;
        NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL];
        item.isDirectory = [[attributes fileType] isEqualToString:NSFileTypeDirectory];
        [items addObject:item];

    }];
    
    self.items = items;
    
    [self finishLoading];
}

@end
