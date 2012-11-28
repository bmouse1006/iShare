//
//  FilePickerDataSource.h
//  iShare
//
//  Created by Jin Jin on 12-8-5.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FileOperationWrap.h"

@interface FilePickerDataSource : NSObject<UITableViewDataSource>

@property (nonatomic, assign) FileContentType filterType;

-(id)initWithFilePath:(NSString*)filePath filterType:(FileContentType)type;
-(void)refresh;

-(id)objectAtIndexPath:(NSIndexPath*)indexPath;
-(NSArray*)objectsForIndexPaths:(NSArray*)indexPaths;

@end
