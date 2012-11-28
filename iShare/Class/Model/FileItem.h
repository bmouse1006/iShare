//
//  FileItem.h
//  iShare
//
//  Created by Jin Jin on 12-8-4.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuickLook/QuickLook.h>

typedef enum {
    FileItemTypeFilePath,
    FileItemTypeActionMenu
} FileItemType;

@interface FileItem : NSObject<QLPreviewItem>

@property (nonatomic, assign) FileItemType type;
@property (nonatomic, copy) NSString* filePath;
@property (nonatomic, strong) NSDictionary* attributes;

@end
