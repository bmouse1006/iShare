//
//  TableHeaderRefreshView.h
//  iShare
//
//  Created by Jin Jin on 12-10-3.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    TableHeaderRefreshViewStatusReady,
    TableHeaderRefreshViewStatusRefresh,
    TableHeaderRefreshViewStatusNormal,
} TableHeaderRefreshViewStatus;

@class TableHeaderRefreshView;

@protocol TableHeaderRefreshViewDelegate <NSObject>

-(void)tableViewStartRefreshing:(TableHeaderRefreshView*)refreshView;
-(void)tableViewEndRefreshing:(TableHeaderRefreshView*)refreshView;

@end

@interface TableHeaderRefreshView : UIView

@property (nonatomic, copy) NSString* title;//normal status
@property (nonatomic, copy) NSString* readyTitle;//ready for refreshing
@property (nonatomic, copy) NSString* refreshTitle;

@property (nonatomic, assign) TableHeaderRefreshViewStatus status;

@property (nonatomic, strong) IBOutlet UILabel* textLabel;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView* activityView;

-(void)changeToRefreshStatus:(TableHeaderRefreshViewStatus)status;

@end
