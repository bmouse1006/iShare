//
//  ISPhotoBrowserDelegate.h
//  iShare
//
//  Created by Jin Jin on 12-8-12.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWPhotoBrowser.h"

@interface ISPhotoBrowserDelegate : NSObject<MWPhotoBrowserDelegate>

-(id)initWithImageFilePaths:(NSArray*)filePaths;

@end
