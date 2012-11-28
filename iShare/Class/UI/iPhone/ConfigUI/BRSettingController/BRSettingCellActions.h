//
//  BRSettingCellActions.h
//  BreezyReader2
//
//  Created by 金 津 on 12-5-13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BRSettingCellActions <NSObject>

@optional

-(void)valueChangedForIdentifier:(NSString*)identifier newValue:(id)value;

@end
