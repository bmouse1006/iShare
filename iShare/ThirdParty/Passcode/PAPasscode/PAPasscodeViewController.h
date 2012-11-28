//
//  PAPasscodeViewController.h
//  PAPasscode
//
//  Created by Denis Hennessy on 15/10/2012.
//  Copyright (c) 2012 Peer Assembly. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^PasscodeDidChangeBlock)(void);
typedef void(^PasscodeDidEnterBlock)(void);
typedef void(^PasscodeDidSetBlock)(void);
typedef void(^PasscodeDidCancelBlock)(void);
typedef void(^PasscodeDidFailedAttemptBlock)(NSInteger);

typedef enum {
    PasscodeActionSet,
    PasscodeActionEnter,
    PasscodeActionChange
} PasscodeAction;

@class PAPasscodeViewController;

@protocol PAPasscodeViewControllerDelegate <NSObject>

- (void)PAPasscodeViewControllerDidCancel:(PAPasscodeViewController *)controller;

@optional

- (void)PAPasscodeViewControllerDidChangePasscode:(PAPasscodeViewController *)controller;
- (void)PAPasscodeViewControllerDidEnterPasscode:(PAPasscodeViewController *)controller;
- (void)PAPasscodeViewControllerDidSetPasscode:(PAPasscodeViewController *)controller;
- (void)PAPasscodeViewController:(PAPasscodeViewController *)controller didFailToEnterPasscode:(NSInteger)attempts;

@end

@interface PAPasscodeViewController : UIViewController {
    UIView *contentView;
    NSInteger phase;
    UILabel *promptLabel;
    UILabel *messageLabel;
    UIImageView *failedImageView;
    UILabel *failedAttemptsLabel;
    UITextField *passcodeTextField;
    UIImageView *digitImageViews[4];
    UIImageView *snapshotImageView;
}

@property (readonly) PasscodeAction action;
@property (weak) id<PAPasscodeViewControllerDelegate> delegate;
@property (strong) NSString *passcode;
@property (assign) BOOL simple;
@property (assign) BOOL noCancel;
@property (assign) NSInteger failedAttempts;
@property (strong) NSString *enterPrompt;
@property (strong) NSString *confirmPrompt;
@property (strong) NSString *changePrompt;
@property (strong) NSString *message;

@property (copy) PasscodeDidCancelBlock didCancelBlock;
@property (copy) PasscodeDidSetBlock didSetBlock;
@property (copy) PasscodeDidEnterBlock didEnterBlock;
@property (copy) PasscodeDidChangeBlock didChangeBlock;
@property (copy) PasscodeDidFailedAttemptBlock didFailedAttemptBlock;

- (id)initForAction:(PasscodeAction)action;

@end
