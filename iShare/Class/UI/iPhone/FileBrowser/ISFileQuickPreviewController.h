//
//  ISFileQuickPreviewController.h
//  iShare
//
//  Created by Jin Jin on 12-8-12.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <QuickLook/QuickLook.h>

@interface ISFileQuickPreviewController : QLPreviewController<QLPreviewControllerDelegate, QLPreviewControllerDataSource>

-(id)initWithPreviewItems:(NSArray*)items;

@end
