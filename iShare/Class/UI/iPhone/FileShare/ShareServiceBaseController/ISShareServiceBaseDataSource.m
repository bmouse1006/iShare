//
//  ISShareServiceBaseDataSource.m
//  iShare
//
//  Created by Jin Jin on 12-8-26.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISShareServiceBaseDataSource.h"
#import "ISShareServiceTableViewCell.h"
#import "FileShareServiceItem.h"
#import "FileOperationWrap.h"

@interface ISShareServiceBaseDataSource ()

@property (nonatomic, assign) BOOL loading;

@end

@implementation ISShareServiceBaseDataSource

-(id)initWithWorkingPath:(NSString*)workingPath{
    self = [super init];
    if (self){
        self.workingPath = workingPath;
    }
    
    return self;
}

-(void)startLoading{
    self.loading = YES;
    [self loadContent];
}

-(void)loadContent{
    
}

-(void)finishLoading{
    //sort result
    [self.items sortUsingComparator:^(FileShareServiceItem* item1, FileShareServiceItem* item2){
        NSComparisonResult result = NSOrderedSame;
        if (item1.isDirectory && !item2.isDirectory){
            result = NSOrderedAscending;
        }else if (!item1.isDirectory && item2.isDirectory){
            result = NSOrderedDescending;
        }else{
            result = [[[item1.filePath lastPathComponent] lowercaseString] compare:[[item2.filePath lastPathComponent] lowercaseString]];
        }
        
        return result;
    }];

    if ([self.delegate respondsToSelector:@selector(dataSourceDidFinishLoading:)]){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate dataSourceDidFinishLoading:self];
        });
    }
    self.loading = NO;
}

-(void)failedLoading:(NSError*)error{
    if ([self.delegate respondsToSelector:@selector(dataSourceDidFailLoading:error:)]){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate dataSourceDidFailLoading:self error:error];
        });
    }
    self.loading = NO;
}

-(BOOL)isLoading{
    return self.loading;
}

-(id)objectAtIndexPath:(NSIndexPath *)indexPath{
    return [self.items objectAtIndex:indexPath.row];
}

-(void)removeObjectAtIndexPath:(NSIndexPath*)indexPath{
    [self.items removeObjectAtIndex:indexPath.row];
}

#pragma mark - data source methods
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.items count];
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ISShareServiceTableViewCell* cell = [[ISShareServiceTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    FileShareServiceItem* item = [self.items objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [item.filePath lastPathComponent];
    
//    if ([FileOperationWrap fileTypeWithFilePath:item.filePath] == FileContentTypeDirectory){
    if (item.isDirectory){
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.imageView.image = [UIImage imageNamed:@"fileicon_folder"];
    }else{
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.imageView.image = [FileOperationWrap thumbnailForFile:item.filePath previewEnabled:NO];
    }
    
    return cell;
}

@end
