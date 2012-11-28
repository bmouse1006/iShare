//
//  TableHeaderRefreshView.m
//  iShare
//
//  Created by Jin Jin on 12-10-3.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "TableHeaderRefreshView.h"

@implementation TableHeaderRefreshView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)awakeFromNib{
    [super awakeFromNib];
    self.autoresizingMask = UIViewAutoresizingNone;
}

-(void)changeToRefreshStatus:(TableHeaderRefreshViewStatus)status{
    self.status = status;
    switch (self.status) {
        case TableHeaderRefreshViewStatusNormal:
            self.textLabel.text = self.title;
            [self.activityView stopAnimating];
            break;
        case TableHeaderRefreshViewStatusReady:
            self.textLabel.text = self.readyTitle;
            [self.activityView stopAnimating];
            break;
        case TableHeaderRefreshViewStatusRefresh:
            self.textLabel.text = self.refreshTitle;
            self.activityView.hidden = NO;
            [self.activityView startAnimating];
            break;
        default:
            break;
    }
}

@end
