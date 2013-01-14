//
//  JJMoviePlayerViewController.h.h
//  iShare
//
//  Created by Jin Jin on 12-12-21.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JJMoviePlayerController.h"

@interface JJMoviePlayerViewController : UIViewController<JJMoviePlayerControllerDelegate>

-(id)initWithFilepath:(NSString*)filepath;

@end
