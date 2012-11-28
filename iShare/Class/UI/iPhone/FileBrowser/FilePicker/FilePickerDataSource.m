//
//  FilePickerDataSource.m
//  iShare
//
//  Created by Jin Jin on 12-8-5.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "FilePickerDataSource.h"
#import "ISFileBrowserCell.h"
#import "FileItem.h"

@interface FilePickerDataSource()

@property (nonatomic, copy) NSString* filePath;

@property (nonatomic, retain) NSArray* fileItems;

@end

@implementation FilePickerDataSource

-(id)initWithFilePath:(NSString*)filePath filterType:(FileContentType)type{
    self = [super init];
    
    if (self){
        self.filePath = filePath;
        self.filterType = type;
    }
    
    return self;
}

-(void)refresh{
    NSArray* fileItems = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.filePath error:NULL];
    NSMutableArray* allItems = [NSMutableArray array];
    [fileItems enumerateObjectsUsingBlock:^(NSString* filename, NSUInteger idx, BOOL* stop){
        if ([filename hasPrefix:@"."]){
            return;
        }
        FileItem* item = [[FileItem alloc] init];
        item.filePath = [self.filePath stringByAppendingPathComponent:filename];
        item.type = FileItemTypeFilePath;
        
        if (self.filterType & [FileOperationWrap fileTypeWithFilePath:item.filePath]){
            [allItems addObject:item];
        }
    }];
    
    [allItems sortUsingComparator:^(FileItem* item1, FileItem* item2){
        NSString* fileType1 = [item1.attributes fileType];
        NSString* fileType2 = [item2.attributes fileType];
        if ([fileType1 isEqualToString:NSFileTypeDirectory] && ![fileType2 isEqualToString:NSFileTypeDirectory]){
            return NSOrderedAscending;
        }else if (![fileType1 isEqualToString:NSFileTypeDirectory] && [fileType2 isEqualToString:NSFileTypeDirectory]){
            return NSOrderedDescending;
        }else{
            return (NSInteger)[[[item1.filePath lastPathComponent] lowercaseString] compare:[[item2.filePath lastPathComponent] lowercaseString]];
        }
    }];
    
    self.fileItems = allItems;

}

-(NSArray*)objectsForIndexPaths:(NSArray*)indexPaths{
    NSMutableArray* filteredItems = [NSMutableArray array];
    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath* indexPath, NSUInteger idx, BOOL* stop){
        [filteredItems addObject:[self.fileItems objectAtIndex:indexPath.row]];
    }];
    return filteredItems;
}

-(id)objectAtIndexPath:(NSIndexPath*)indexPath{
    return [self.fileItems objectAtIndex:indexPath.row];
}

#pragma mark - data source methods
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.fileItems count];
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString* CellIdentifier = @"FilePickerCell";
    ISFileBrowserCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil){
        cell = [[[NSBundle mainBundle] loadNibNamed:@"ISFileBrowserCell" owner:nil options:nil] objectAtIndex:0];
    }
    
    [cell configCell:[self.fileItems objectAtIndex:indexPath.row]];
    
    return cell;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    FileItem* item = [self objectAtIndexPath:indexPath];
    return [[item.attributes fileType] isEqualToString:NSFileTypeDirectory] == NO;
}

@end
