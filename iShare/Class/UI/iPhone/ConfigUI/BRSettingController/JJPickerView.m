//
//  JJPicker.m
//  BreezyReader2
//
//  Created by 金 津 on 12-5-15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "JJPickerView.h"

@implementation JJPickerView

@synthesize picker = _picker, pickerContainer = _pickerContainer;
@synthesize delegate = _delegate, dataSource = _dataSource;
@synthesize titleLabel = _titleLabel;


-(void)awakeFromNib{
    [super awakeFromNib];
}

-(void)show{
    [super show];
    CGRect frame = self.pickerContainer.frame;
    frame.origin.y = self.frame.size.height;
    self.pickerContainer.frame = frame;
    
    frame.origin.y -= frame.size.height;
    
    [UIView animateWithDuration:BASEVIEW_ANIMATION_DURATION animations:^{
        self.pickerContainer.frame = frame;
    }];
}

-(void)dismiss{
    [super dismiss];
    CGRect frame = self.pickerContainer.frame;
    frame.origin.y += frame.size.height;
    
    [UIView animateWithDuration:BASEVIEW_ANIMATION_DURATION animations:^{
        self.pickerContainer.frame = frame; 
    }];
}

#pragma mark - forward message
- (void)forwardInvocation:(NSInvocation *)anInvocation{
    [anInvocation setTarget:self.picker];
    [anInvocation invoke];
    return;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector{
    if ([self.picker respondsToSelector:aSelector]){
        return [self.picker methodSignatureForSelector:aSelector];
    }else{
        return [super methodSignatureForSelector:aSelector];
    }
}

#pragma mark - setter
-(void)setDelegate:(id<UIPickerViewDelegate>)delegate{
    self.picker.delegate = delegate;
}

-(void)setDataSource:(id<UIPickerViewDataSource>)dataSource{
    self.picker.dataSource = dataSource;
}

#pragma mark - data source
//-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
//    return [self.dataSource pickerView:pickerView numberOfRowsInComponent:component];
//}
//
//-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
//    return [self.dataSource numberOfComponentsInPickerView:pickerView];
//}

#pragma mark - delegate
//- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component{
//    if ([self.delegate respondsToSelector:@selector(pickerView:widthForComponent:)]){
//        [self.delegate pickerView:pickerView widthForComponent:component];
//    }
//}
//- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component{
//    if ([self.delegate respondsToSelector:@selector(pickerView:rowHeightForComponent:)]){
//        [self.delegate pickerView:pickerView rowHeightForComponent:component];
//    }
//}
//
//// these methods return either a plain UIString, or a view (e.g UILabel) to display the row for the component.
//// for the view versions, we cache any hidden and thus unused views and pass them back for reuse. 
//// If you return back a different object, the old one will be released. the view will be centered in the row rect  
//- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
//    if ([self.delegate respondsToSelector:@selector(pickerView:titleForRow:forComponent:)]){
//        [self.delegate pickerView:pickerView titleForRow:row forComponent:component];
//    }
//}
//- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
//    if ([self.delegate respondsToSelector:@selector(pickerView:viewForRow:forComponent:reusingView:)]){
//        [self.delegate pickerView:pickerView viewForRow:row forComponent:component reusingView:view];
//    }
//}
//
//- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
//    if ([self.delegate respondsToSelector:@selector(pickerView:didSelectRow:inComponent:)]){
//        [self.delegate pickerView:pickerView didSelectRow:row inComponent:<#(NSInteger)#>];
//    }
//}

@end
