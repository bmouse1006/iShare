//
//  ISBTSendingCell.m
//  iShare
//
//  Created by Jin Jin on 12-10-16.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "ISBTSendingCell.h"
#import "FileOperationWrap.h"

@interface ISBTSendingCell ()

@property (nonatomic, strong) JJBTSender* sender;

@end

@implementation ISBTSendingCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)configCell:(JJBTSender*)sender{
    self.sender = sender;
    self.textLabel.text = [sender name];
    self.identifier = [sender identifier];
    [self updateCell];
//    self.detailTextLabel.text = [sender]
    //finished size and totle size
}

-(void)updateCell{
    if ([self.sender isExecuting]){
        self.detailTextLabel.text = [NSString stringWithFormat:@"%@/%@", [FileOperationWrap normalizedSize:self.sender.finishedSize], [FileOperationWrap normalizedSize:[self.sender sizeOfObject]]];
    }else{
        self.detailTextLabel.text = [NSString stringWithFormat:@"%@", [FileOperationWrap normalizedSize:[self.sender sizeOfObject]]];
    }
}

@end
