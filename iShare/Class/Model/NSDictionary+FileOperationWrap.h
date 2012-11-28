//
//  NSDictionary+FileOperationWrap.h
//  iShare
//
//  Created by Jin Jin on 12-9-25.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (FileOperationWrap)

-(NSString*)normalizedFileSize;
-(NSString*)shortLocalizedModificationDate;
-(NSString*)modificationDateWithFormate:(NSString*)formate;

@end
