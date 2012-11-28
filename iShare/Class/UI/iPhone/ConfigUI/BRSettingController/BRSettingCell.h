//
//  BRSettingCell.h
//  BreezyReader2
//
//  Created by 金 津 on 12-5-13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BRSettingCellActions.h"

@interface BRSettingCell : UITableViewCell

@property (nonatomic, unsafe_unretained) id<BRSettingCellActions> delegate;

-(void)setCellConfig:(NSDictionary*)dictionary;
-(void)updateCell;

@end
