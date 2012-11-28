//
//  JJBTFileSharer.m
//  iShare
//
//  Created by Jin Jin on 12-9-6.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "JJBTFileSharer.h"
#import "JJBTFileSender.h"
#import "JJBTPhotoSender.h"
#import "FileItem.h"
#import "FileOperationWrap.h"
#import <AssetsLibrary/AssetsLibrary.h>

typedef enum {
    PackageTypeStart,
    PackageTypeEnd,
    PackageTypeData
} PackageType;

@interface JJBTFileSharer (){
    JJBTFileSharerStatus _status;
}

@property (nonatomic, strong) GKSession* session;
@property (nonatomic, readonly) NSString* storePath;
@property (nonatomic, strong) NSOutputStream* writeStream;

@property (nonatomic, strong) NSOperationQueue* sendingQueue;

@property (nonatomic, copy) NSString* receivingIdentifier;

@end

@implementation JJBTFileSharer

-(id)init{
    self = [super init];
    if (self){
        self.sendingQueue = [[NSOperationQueue alloc] init];
        self.sendingQueue.maxConcurrentOperationCount = 1;
        [self.sendingQueue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionOld context:nil];
    }
    
    return self;
}

+(id)defaultSharer{
    static dispatch_once_t onceToken;
    static JJBTFileSharer* sharer = nil;
    dispatch_once(&onceToken, ^{
        sharer = [[JJBTFileSharer alloc] init];
    });
    
    return sharer;
}

+(void)setDefaultGKSession:(GKSession*)session{
    JJBTFileSharer* sharer = [self defaultSharer];
    session.delegate = sharer;
    sharer.session = session;
    [sharer.session setDataReceiveHandler:sharer withContext:NULL];
}

-(NSString*)nameOfPair{
    NSArray* peers = [self.session peersWithConnectionState:GKPeerStateConnected];
    return [self.session displayNameForPeer:[peers lastObject]];
}

-(BOOL)isConnected{
    return [self nameOfPair].length > 0;
}

-(NSString*)storePath{
    return [[FileOperationWrap homePath] stringByAppendingPathComponent:NSLocalizedString(@"title_receivedfrombluetooth", nil)];
}

-(void)cancelSending{
    [self.sendingQueue cancelAllOperations];
}

-(void)cancelReceiving{
    self.receivingIdentifier = nil;
    ReceivedBytes = 0;
    ReceivingType = BTSenderTypeUnknown;
}

-(void)endSession{
    [self.sendingQueue cancelAllOperations];
    [self.session disconnectFromAllPeers];
}

-(void)sendFiles:(NSArray*)files{
    _status = JJBTFileSharerStatusSending;
    //tell that will send bunch of files
    [self.sendingQueue setSuspended:YES];
    [files enumerateObjectsUsingBlock:^(FileItem* file, NSUInteger idx, BOOL* stop){
        JJBTFileSender* fileSender = [[JJBTFileSender alloc] init];
        fileSender.delegate = self;
        fileSender.session = self.session;
        fileSender.sendingObj = file.filePath;
        [self.sendingQueue addOperation:fileSender];
    }];
    
    NSMutableArray* filePaths = [NSMutableArray array];
    NSArray* senders = [self.sendingQueue operations];
    [senders enumerateObjectsUsingBlock:^(JJBTSender* sender, NSUInteger idx, BOOL* stop){
        NSString* name = [sender name];
        NSString* size = [NSString stringWithFormat:@"%llu", [sender sizeOfObject]];
        NSString* identifier = [sender identifier];
        [filePaths addObject:@{@"name" : name, @"size":size, @"identifier":identifier}];
    }];
    [self sendBundleHeadWithType:BTSenderTypeFile list:filePaths];
    
    [self.sendingQueue setSuspended:NO];
}

-(NSArray*)allSenders{
    return [self.sendingQueue operations];
}

- (void) receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context{
    //data receiveing handler
    //check package head
    DebugLog(@"reveiving data");
    
    NSUInteger length = [data length];
    UInt8 *buff = (UInt8*)[data bytes];

    NSData* contentData = [NSData dataWithBytes:buff+BTBlockHeadSize length:length-BTBlockHeadSize];
    
    switch (buff[0]) {
        case BTTransitionBlockTypeHead:
            [self startReceiving:contentData];
            break;
        case BTTransitionBlockTypeTail:
            [self finishedReceiving:contentData];
            break;
        case BTTransitionBlockTypeBody:
            [self receivedData:contentData];
            break;
        case BTTransitionBlockTypeError:
            [self receivingErrorHappened:contentData];
            break;
        case BTTransitionBlockTypeBundleHead:
            [self receivedBundleHead:contentData];
            break;
        case BTTransitionBlockTypeBundleTail:
            [self receivedBundleTail:contentData];
            break;
        default:
            break;
    }
}

-(void)cancelAllTransitions{
    [self cancelSending];
    [self cancelReceiving];
}

#pragma mark - content receiving handler

static long long ReceivedBytes = 0;
static BTSenderType ReceivingType = BTSenderTypeUnknown;

-(void)receivedBundleHead:(NSData*)bundleHead{
    NSMutableDictionary* bundleContent = [NSJSONSerialization JSONObjectWithData:bundleHead options:NSJSONReadingMutableContainers error:NULL];
    
    if ([self.delegate respondsToSelector:@selector(sharerDidStartReceiving:headContent:)]){
        [self.delegate sharerDidStartReceiving:self headContent:bundleContent];
    }
}

-(void)receivedBundleTail:(NSData*)bundleTail{
    if ([self.delegate respondsToSelector:@selector(sharerDidEndReceiving:)]){
        [self.delegate sharerDidEndReceiving:self];
    }
}

-(void)startReceiving:(NSData*)head{
    ReceivedBytes = 0;
    NSDictionary* headContent = [NSJSONSerialization JSONObjectWithData:head options:NSJSONReadingAllowFragments error:NULL];

    ReceivingType = [[headContent objectForKey:@"type"] intValue];
    NSString* name = [headContent objectForKey:@"name"];
    NSString* version = [headContent objectForKey:@"version"];
    NSString* identifier = [headContent objectForKey:@"identifier"];
    if ([version isEqualToString:CurrentVersion]){
        self.receivingIdentifier = identifier;
    }else{
        self.receivingIdentifier = nil;
        return;
    }
//    long long size = [[headContent objectForKey:@"size"] longLongValue];
    
    switch (ReceivingType) {
        case BTSenderTypeFile:
            [self startReceivingFile:name];
            break;
        case BTSenderTypePhoto:
            [self startReceivingPhoto];
            break;
        case BTSenderTypeUnknown:
            break;
        default:
            break;
    }
}

-(void)finishedReceiving:(NSData*)tail{
    if (ReceivingType == BTSenderTypeFile){
        [self fileReceivingFinished];
    }else if (ReceivingType == BTSenderTypePhoto){
        [self photoReceivingFinished];
    }
    
    if ([self.delegate respondsToSelector:@selector(sharer:finishedReceivingWithIdentifier:)]){
        [self.delegate sharer:self finishedReceivingWithIdentifier:self.receivingIdentifier];
    }
}

-(void)receivedData:(NSData*)data{
    NSUInteger length = [data length];
    ReceivedBytes += length;
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.writeStream write:[data bytes] maxLength:length];
        //当前传输的块属于哪个传输事务？
        //finished size notification
        if ([self.delegate respondsToSelector:@selector(sharer:didReceiveBytes:identifier:)]){
            [self.delegate sharer:self didReceiveBytes:ReceivedBytes identifier:self.receivingIdentifier];
            }
//    });
}

-(void)receivingErrorHappened:(NSData*)data{
    [self.writeStream close];
    self.writeStream = nil;
}

#pragma mark - receiving file
-(void)startReceivingFile:(NSString*)name{
    NSString* filePath = [FileOperationWrap validFilePathForFilename:name atPath:self.storePath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.storePath] == NO){
        [[NSFileManager defaultManager] createDirectoryAtPath:self.storePath withIntermediateDirectories:NO attributes:nil error:NULL];
    }
    
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    
    self.writeStream = [NSOutputStream outputStreamToFileAtPath:filePath append:NO];
    [self.writeStream open];
}

-(void)fileReceivingFinished{
    [self.writeStream close];
    self.writeStream = nil;
}

#pragma mark - receiving photo
-(void)startReceivingPhoto{
    //create temp file
    NSString* tempFile = [[FileOperationWrap tempFolder] stringByAppendingPathComponent:@"receivingImage"];
    [[NSFileManager defaultManager] removeItemAtPath:tempFile error:NULL];
    [[NSFileManager defaultManager] createFileAtPath:tempFile contents:nil attributes:nil];
    
    self.writeStream = [NSOutputStream outputStreamToFileAtPath:tempFile append:NO];
    [self.writeStream open];
}

-(void)photoReceivingFinished{
    //save photo to album
    [self.writeStream close];
    self.writeStream = nil;
    
    NSString* tempFile = [[FileOperationWrap tempFolder] stringByAppendingPathComponent:@"receivingImage"];
    NSData* imageData = [NSData dataWithContentsOfFile:tempFile];
    UIImage* image = [UIImage imageWithData:imageData];
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    //saved
    if (error){
        DebugLog(@"error happened: %@", [error localizedDescription]);
    }
}

#pragma mark - send photos
-(void)sendPhotos:(NSArray*)photos{
    //send photots
    
    _status = JJBTFileSharerStatusSending;
    //tell that will send bunch of files
    [self.sendingQueue setSuspended:YES];
    [photos enumerateObjectsUsingBlock:^(ALAsset* asset, NSUInteger idx, BOOL* stop){
        JJBTPhotoSender* photoSender = [[JJBTPhotoSender alloc] init];
        photoSender.delegate = self;
        photoSender.session = self.session;
        photoSender.sendingObj = asset;
        [self.sendingQueue addOperation:photoSender];
    }];
    
    NSMutableArray* sendingInfo = [NSMutableArray array];
    NSArray* senders = [self.sendingQueue operations];
    [senders enumerateObjectsUsingBlock:^(JJBTSender* sender, NSUInteger idx, BOOL* stop){
        NSString* name = [sender name];
        NSString* size = [NSString stringWithFormat:@"%llu", [sender sizeOfObject]];
        NSString* identifier = [sender identifier];
        [sendingInfo addObject:@{@"name" : name, @"size":size, @"identifier":identifier}];
    }];
    
    [self sendBundleHeadWithType:BTSenderTypePhoto list:sendingInfo];
    
    [self.sendingQueue setSuspended:NO];
}

#pragma mark - gk session delegate
-(void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state{
    if ([[self.session peersWithConnectionState:GKPeerStateConnected] count] == 0 && state == GKPeerStateDisconnected){
        //cancel all trancision tasks
        [self cancelAllTransitions];
        //tell delegate that i'm failed
        [self.delegate sharerIsDisconnectedWithPair:self];
    }
}

-(void)session:(GKSession *)session didFailWithError:(NSError *)error{
    [self cancelAllTransitions];
    [self.delegate sharerIsDisconnectedWithPair:self];
}

#pragma mark - BT sender delegate
-(void)btSenderStartedSending:(JJBTSender*)sender{
    DebugLog(@"staring sending");
}

-(void)btSender:(JJBTSender*)sender finishedBytes:(long long)finishedBytes{
    DebugLog(@"finished bytes %llu", finishedBytes);
    if ([self.delegate respondsToSelector:@selector(sharer:didSendBytes:identifier:)]){
        [self.delegate sharer:self didSendBytes:finishedBytes identifier:[sender identifier]];
    }
}

-(void)btSenderFinishedSending:(JJBTSender*)sender{
    DebugLog(@"finished sending sender %@", [sender description]);
    if ([self.delegate respondsToSelector:@selector(sharer:finishedSendingWithIdentifier:)]){
        [self.delegate sharer:self finishedSendingWithIdentifier:[sender identifier]];
    }
    [self updateSharerStatus];
}

-(void)btSenderCancelledSending:(JJBTSender*)sender{
    DebugLog(@"cancelled sending sender %@", [sender description]);
    [self updateSharerStatus];
}

-(void)btSender:(JJBTSender *)sender failedWithError:(NSError*)error{
    DebugLog(@"failed sending sender %@ with error %@", [sender description], [error localizedDescription]);
    [self updateSharerStatus];
}

#pragma mark - status
-(JJBTFileSharerStatus)status{
    return _status;
}

-(void)updateSharerStatus{
    if ([self.sendingQueue operationCount] <= 1){
        _status = JJBTFileSharerStatusStandBy;
    }
}

-(NSInteger)countOfSendingFiles{
    return [self.sendingQueue operationCount];
}

-(NSInteger)countOfReceivingFiles{
    return 0;
}

#pragma mark - key value observer
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if (object == self.sendingQueue && [keyPath isEqualToString:@"operationCount"]){
        NSInteger newCount = [self.sendingQueue operationCount];
        NSInteger oldCount = [[change objectForKey:NSKeyValueChangeOldKey] intValue];
        if (newCount > 0 && oldCount == 0){
            //start sending
            if ([self.delegate respondsToSelector:@selector(sharerDidStartSending:)]){
                [self.delegate sharerDidStartSending:self];
            }
        }else if (oldCount > 0 && newCount == 0){
            //end sending
            if ([self.delegate respondsToSelector:@selector(sharerDidEndSending:)]){
                [self.delegate sharerDidEndSending:self];
            }
            
            [self sendBundleTailWithType:BTTransitionBlockTypeBundleTail];
        }
    }
}

#pragma mark - send bunch head
-(void)sendBundleHeadWithType:(BTSenderType)type list:(NSArray*)list{
    
    NSDictionary* headContent = @{@"type" : [NSString stringWithFormat:@"%d", type], @"list":list, @"version":[JJBTSender version]};
    
    NSData* contentData = [NSJSONSerialization dataWithJSONObject:headContent options:NSJSONReadingAllowFragments error:NULL];
    
    JJBTSender* sender = [[JJBTSender alloc] init];
    
    NSData* sendBlock = [sender blockWithType:BTTransitionBlockTypeBundleHead data:contentData];
    
    [self.session sendDataToAllPeers:sendBlock withDataMode:GKSendDataReliable error:NULL];
}

-(void)sendBundleTailWithType:(BTTransitionBlockType)type{
    JJBTSender* sender = [[JJBTSender alloc] init];
    NSData* sendBlock = [sender blockWithType:BTTransitionBlockTypeBundleTail data:[NSData data]];
    
    [self.session sendDataToAllPeers:sendBlock withDataMode:GKSendDataReliable error:NULL];
}

@end
