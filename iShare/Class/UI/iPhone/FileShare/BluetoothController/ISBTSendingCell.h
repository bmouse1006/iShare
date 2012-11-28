//
//  ISBTSendingCell.h
//  iShare
//
//  Created by Jin Jin on 12-10-16.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JJBTSender.h"

@interface ISBTSendingCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel* titleLabel;
@property (nonatomic, strong) IBOutlet UILabel* sizeLabel;
@property (nonatomic, copy) NSString* identifier;

-(void)configCell:(JJBTSender*)sender;
-(void)updateCell;

@end
