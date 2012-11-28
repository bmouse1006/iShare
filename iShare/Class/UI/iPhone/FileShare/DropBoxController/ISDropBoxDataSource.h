//
//  ISDropBoxDataSource.h
//  iShare
//
//  Created by Jin Jin on 12-8-27.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISShareServiceBaseDataSource.h"
#import <DropboxSDK/DropboxSDK.h>

@interface ISDropBoxDataSource : ISShareServiceBaseDataSource <DBRestClientDelegate>

@end
