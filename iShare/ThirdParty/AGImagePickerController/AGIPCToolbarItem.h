//
//  AGIPCToolbarItem.h
//  AGImagePickerController
//
//  Created by Artur Grigor on 05.03.2012.
//  Copyright (c) 2012 Artur Grigor. All rights reserved.
//  
//  For the full copyright and license information, please view the LICENSE
//  file that was distributed with this source code.
//  

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

typedef BOOL (^AGIPCAssetIsSelectedBlock)(NSUInteger index, ALAsset *asset);

@interface AGIPCToolbarItem : NSObject
{
}

@property (retain) UIBarButtonItem *barButtonItem;
@property (copy) AGIPCAssetIsSelectedBlock assetIsSelectedBlock;

- (id)initWithBarButtonItem:(UIBarButtonItem *)theBarButtonItem;
- (id)initWithBarButtonItem:(UIBarButtonItem *)theBarButtonItem andSelectionBlock:(AGIPCAssetIsSelectedBlock)theSelectionBlock;

@end
