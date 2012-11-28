//
//  FileItem.m
//  iShare
//
//  Created by Jin Jin on 12-8-4.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "FileItem.h"

@implementation FileItem

-(void)setFilePath:(NSString *)filePath{
    _filePath = filePath;
    self.attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:_filePath error:NULL];
}

-(NSURL*)previewItemURL{
    return [NSURL fileURLWithPath:self.filePath];
}

@end
