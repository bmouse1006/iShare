//
//  ISFileBrowserCellInterface.h
//  iShare
//
//  Created by Jin Jin on 12-8-5.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FileItem;

@protocol ISFileBrowserCellInterface <NSObject>

-(FileItem*)cellItem;
-(void)configCell:(FileItem*)item;
-(void)updateCell;

@end
