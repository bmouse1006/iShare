//
//  JJPicker.h
//  BreezyReader2
//
//  Created by 金 津 on 12-5-15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseView.h"

@class JJPickerView;

@protocol JJPickerViewDataSource <NSObject>

@required
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component;
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView;

@end

@interface JJPickerView : BaseView 

@property (nonatomic, strong) IBOutlet UIPickerView* picker;
@property (nonatomic, strong) IBOutlet UIView* pickerContainer;

@property (nonatomic, unsafe_unretained) id<UIPickerViewDelegate> delegate;
@property (nonatomic, unsafe_unretained) id<UIPickerViewDataSource> dataSource;

@property (nonatomic, strong) IBOutlet UILabel* titleLabel;

@end
