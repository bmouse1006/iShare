//
//  JJSMBFileManger.m
//  iShare
//
//  Created by Jin Jin on 12-11-28.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "JJSMBFileManger.h"

@implementation JJSMBFileManger

#pragma mark - open interface of remote file manager
//get a manager with given address
-(id)managerWithAddress:(NSString*)address{
    
}
//setup the username and password for authentication, if any
-(void)setUsername:(NSString*)username password:(NSString*)password{
    
}

//copy item
-(BOOL)copyItemAtPath:(NSString*)path toPath:(NSString *)dstPath error:(NSError *__autoreleasing *)error{
    
}
//move item
- (BOOL)moveItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError *__autoreleasing *)error{
    
}
//remove item
- (BOOL)removeItemAtPath:(NSString *)path error:(NSError *__autoreleasing *)error{
    
}
//create a new directory
- (BOOL)createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)createIntermediates attributes:(NSDictionary *)attributes error:(NSError *__autoreleasing *)error{
    
}
//get attributes of given item
- (BOOL)attributesOfItemAtPath:(NSString *)path error:(NSError *__autoreleasing *)error{
    
}
//list contents of directory
-(BOOL)contentsOfDirectoryAtPath:(NSString *)path error:(NSError *__autoreleasing *)error{
    
}

#pragma mark - method to implement afp client

@end
