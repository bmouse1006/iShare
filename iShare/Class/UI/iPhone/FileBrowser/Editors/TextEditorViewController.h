//
//  TextEditorViewController.h
//  iShare
//
//  Created by Jin Jin on 12-11-26.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TextEditorViewController : UIViewController<UIDocumentInteractionControllerDelegate>

@property (nonatomic, strong) IBOutlet UITextView* textView;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* openInButton;

-(id)initWithFilePath:(NSString*)filePath;

-(IBAction)openInButtonClicked:(id)sender;

@end
