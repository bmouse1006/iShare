//
//  AppDelegate.h
//  iShare
//
//  Created by Jin Jin on 12-7-31.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>

@class MainTabBarController;

@interface AppDelegate : UIResponder <UIApplicationDelegate, DBNetworkRequestDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) MainTabBarController *viewController;

@end
