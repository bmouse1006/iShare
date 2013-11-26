//
//  CustomUIComponents.m
//  iShare
//
//  Created by Jin Jin on 12-8-4.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "CustomUIComponents.h"

@implementation CustomUIComponents

+(void)customizeBarButton{
    UIEdgeInsets barBtnInsets = UIEdgeInsetsMake(0, 4, 0, 4);
    
    UIImage* originNormal = [UIImage imageNamed:@"btn_title_bar_rect"];
    UIImage* resizableNormal = [originNormal resizableImageWithCapInsets:barBtnInsets];
    UIImage* originPressed = [UIImage imageNamed:@"btn_title_bar_rect_pressed"];
    UIImage* resizablePressed = [originPressed resizableImageWithCapInsets:barBtnInsets];
    
    [[UIBarButtonItem appearance] setBackgroundImage:resizableNormal forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackgroundImage:resizablePressed forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    
    [[UIBarButtonItem appearanceWhenContainedIn:[UIToolbar class], nil] setBackButtonBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearanceWhenContainedIn:[UIToolbar class], nil] setBackButtonBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
}

+(void)customizeBackButton{
    UIEdgeInsets backBtnInsets = UIEdgeInsetsMake(0, 14, 0, 5);
    
    UIImage* originNormal = [UIImage imageNamed:@"btn_title_bar_back"];
    UIImage* resizableNormal = [originNormal resizableImageWithCapInsets:backBtnInsets];
    UIImage* originPressed = [UIImage imageNamed:@"btn_title_bar_back_pressed"];
    UIImage* resizablePressed = [originPressed resizableImageWithCapInsets:backBtnInsets];
    
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:resizableNormal forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:resizablePressed forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
}

+(void)customizeNavigationBar{
    UIImage* bg = [UIImage imageNamed:@"bg_title_bar"];
    [[UINavigationBar appearance] setBackgroundImage:bg forBarMetrics:UIBarMetricsDefault];
}

+(void)customizeTableView{
//    [[UITableView appearance] setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_texture"]]];
//    [[UITableView appearance] setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_texture"]]];
}

+(void)customizeSegmentedControl{
    
    UIEdgeInsets insets = UIEdgeInsetsMake(0, 4, 0, 4);
    
    UIImage* backgroundNormal = [[UIImage imageNamed:@"btn_tool_bar_dark_segment_default"]resizableImageWithCapInsets:insets];
    UIImage* backgroundSelected = [[UIImage imageNamed:@"btn_tool_bar_dark_segment_selected"] resizableImageWithCapInsets:insets];
    UIImage* seperatorImage = [UIImage imageNamed:@"btn_tool_bar_dark_segment_separator"];
    
    [[UISegmentedControl appearance] setBackgroundImage:backgroundNormal forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UISegmentedControl appearance] setBackgroundImage:backgroundSelected forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
    [[UISegmentedControl appearance] setDividerImage:seperatorImage forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
}

+(void)customizeButton{
    UIEdgeInsets btnInsets = UIEdgeInsetsMake(4, 5, 4, 5);
    
    UIImage* originNormal = [UIImage imageNamed:@"btn_default"];
    UIImage* resizableNormal = [originNormal resizableImageWithCapInsets:btnInsets];
    UIImage* originPressed = [UIImage imageNamed:@"btn_pressed"];
    UIImage* resizablePressed = [originPressed resizableImageWithCapInsets:btnInsets];
    
    [[UIButton appearance] setBackgroundImage:resizableNormal forState:UIControlStateNormal];
    [[UIButton appearance] setBackgroundImage:resizablePressed forState:UIControlStateHighlighted];
}

+(void)customizeButtonWithFixedBackgroundImages:(UIButton*)button{
    UIEdgeInsets btnInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    
    UIImage* originNormal = [UIImage imageNamed:@"btn_default"];
    UIImage* resizableNormal = [originNormal resizableImageWithCapInsets:btnInsets];
    UIImage* originPressed = [UIImage imageNamed:@"btn_pressed"];
    UIImage* resizablePressed = [originPressed resizableImageWithCapInsets:btnInsets];
    
    [button setBackgroundImage:resizableNormal forState:UIControlStateNormal];
    [button setBackgroundImage:resizablePressed forState:UIControlStateHighlighted];
    
    [button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [button setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.shadowOffset = CGSizeMake(0, 1);
}

+(void)customizeUI{
//    [self customizeButton];
//    [self customizeSegmentedControl];
//    [self customizeBackButton];
//    [self customizeBarButton];
//    [self customizeNavigationBar];
//    [self customizeTableView];
}

@end
