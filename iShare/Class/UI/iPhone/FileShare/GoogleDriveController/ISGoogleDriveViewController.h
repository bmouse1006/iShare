//
//  ISGoogleDriveViewController.h
//  iShare
//
//  Created by Jin Jin on 12-11-28.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISShareServiceBaseController.h"

@interface ISGoogleDriveViewController : ISShareServiceBaseController

+(BOOL)canAutherize;
+(void)removeAutherize;

@end
