//
//  ISDropBoxViewController.h
//  iShare
//
//  Created by Jin Jin on 12-8-26.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISShareServiceBaseController.h"
#import <DropboxSDK/DropboxSDK.h>

@interface ISDropBoxViewController : ISShareServiceBaseController<DBSessionDelegate, UIAlertViewDelegate, DBRestClientDelegate>

@end
