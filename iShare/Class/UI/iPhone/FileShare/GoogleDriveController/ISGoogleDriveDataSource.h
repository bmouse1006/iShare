//
//  ISGoogleDriveDataSource.h
//  iShare
//
//  Created by Jin Jin on 12-11-28.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISShareServiceBaseDataSource.h"
#import "GTLDrive.h"

@interface ISGoogleDriveDataSource : ISShareServiceBaseDataSource

@property (nonatomic, strong) GTLServiceDrive* driveSerivce;

@end
