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

@property (nonatomic, strong) IBOutlet UINavigationBar* navigationBar;
@property (nonatomic, strong) IBOutlet UIView* controlerPanel;
@property (nonatomic, strong) IBOutlet UIButton* playControlBtn;
@property (nonatomic, strong) IBOutlet UIView* playStatusView;
@property (nonatomic, strong) IBOutlet UISlider* volumeBar;
@property (nonatomic, strong) IBOutlet UISlider* playProgress;

-(id)initWithFilepath:(NSString*)filepath;

@end
