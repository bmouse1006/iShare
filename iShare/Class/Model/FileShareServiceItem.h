//
//  FileShareServiceItem.h
//  iShare
//
//  Created by Jin Jin on 12-8-26.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    FileShareServiceTypeiCloud,
    FileShareServiceTypeSkydrive,
    FileShareServiceTypeDropBox,
    FileShareServiceTypeGDrive
} FileShareServiceType;

typedef enum {
    FileShareItemTypeDirectory,
    FileShareItemTypeFile
} FileShareItemType;

@interface FileShareServiceItem : NSObject

@property (nonatomic, assign) FileShareServiceType serviceType;
@property (nonatomic, assign) BOOL isDirectory;

@property (nonatomic, copy) NSString* filePath;

@end
