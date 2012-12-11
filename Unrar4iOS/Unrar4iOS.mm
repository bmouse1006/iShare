//
//  Unrar4iOS.mm
//  Unrar4iOS
//
//  Created by Rogerio Pereira Araujo on 10/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Unrar4iOS.h"
#import "RARExtractException.h"

static void(^ThrowRARException)(int) = ^(int PFCode){
    if(PFCode == ERAR_MISSING_PASSWORD) {
        @throw [RARExtractException exceptionWithStatus:RARArchiveProtected];
    }
    if(PFCode == ERAR_BAD_ARCHIVE) {
        @throw [RARExtractException exceptionWithStatus:RARArchiveInvalid];
    }
    if(PFCode == ERAR_UNKNOWN_FORMAT) {
        @throw [RARExtractException exceptionWithStatus:RARArchiveBadFormat];
    }
    if(PFCode == ERAR_BAD_DATA) {
        @throw [RARExtractException exceptionWithStatus:RARArchiveBadData];
    }
};

@interface Unrar4iOS(PrivateMethods)
-(BOOL)_unrarOpenFile:(NSString*)rarFile inMode:(NSInteger)mode;
-(BOOL)_unrarOpenFile:(NSString*)rarFile withpassword:(NSString*)password;
-(BOOL)_unrarOpenFile:(NSString*)rarFile inMode:(NSInteger)mode withPassword:(NSString*)password;
-(BOOL)_unrarCloseFile;
@end

@implementation Unrar4iOS

int CALLBACK CallbackProc(UINT msg, long UserData, long P1, long P2) {
	UInt8 **buffer;
	
	switch(msg) {
		case UCM_CHANGEVOLUME:
			break;
		case UCM_PROCESSDATA:
			buffer = (UInt8 **) UserData;
            if (buffer){
                memcpy(*buffer, (UInt8 *)P1, P2);
                // advance the buffer ptr, original m_buffer ptr is untouched
                *buffer += P2;
            }
			break;
		case UCM_NEEDPASSWORD:
            
			break;
	}
	return(0);
}

-(BOOL) _unrarOpenFile:(NSString*)rarFile inMode:(NSInteger)mode{
	
    return [self _unrarOpenFile:rarFile inMode:mode withPassword:nil];
}

-(BOOL) _unrarOpenFile:(NSString*)rarFile withPassword:(NSString*)aPassword {
	
    return [self _unrarOpenFile:rarFile inMode:RAR_OM_LIST withPassword:aPassword];
}

- (BOOL)_unrarOpenFile:(NSString *)rarFile inMode:(NSInteger)mode withPassword:(NSString *)aPassword {
    
	header = new RARHeaderDataEx;
	flags  = new RAROpenArchiveDataEx;
	
	const char *filenameData = (const char *) [rarFile UTF8String];
	flags->ArcName = new char[strlen(filenameData) + 1];
	strcpy(flags->ArcName, filenameData);
	flags->ArcNameW = NULL;
	flags->CmtBuf = NULL;
	flags->OpenMode = mode;
	
	_rarFile = RAROpenArchiveEx(flags);

	if (flags->OpenResult != 0){
        @throw [RARExtractException exceptionWithStatus:RARArchiveBadFormat];
		return NO;
    }
	
	header->CmtBuf = NULL;
    
    if(aPassword != nil) {
        char *password = (char *) [aPassword UTF8String];
        RARSetPassword(_rarFile, password);
    }
    
	return YES;
}

static int unrarCallback (UINT msg,LPARAM UserData,LPARAM P1,LPARAM P2){
    return 0;
}

-(NSArray *) unrarListFiles {
	int RHCode = 0, PFCode = 0;
    
	[self _unrarOpenFile:self.filename inMode:RAR_OM_LIST withPassword:self.password];
	
	NSMutableArray *files = [NSMutableArray array];
	while ((RHCode = RARReadHeaderEx(_rarFile, header)) == 0) {
		NSString * filename= [NSString stringWithCString:header->FileName encoding:NSASCIIStringEncoding];
		[files addObject:filename];
		
		if ((PFCode = RARProcessFile(_rarFile, RAR_SKIP, NULL, NULL)) != 0) {
			[self _unrarCloseFile];
            ThrowRARException(PFCode);
			return nil;
		}
	}
    
	[self _unrarCloseFile];
	return files;
}

-(BOOL) unrarFileTo:(NSString*)path overWrite:(BOOL)overwrite {
	
    int RHCode=0,PFCode=0;
    
    if ([self _unrarOpenFile:self.filename inMode:RAR_OM_EXTRACT withPassword:self.password]){
        
        while((RHCode=RARReadHeaderEx(_rarFile, header))==0){

            size_t length = header->UnpSize;
            
            if (length <= 0) { // archived file not found
                [self _unrarCloseFile];
                return NO;
            }
            
            RARSetCallback(_rarFile, CallbackProc, NULL);
            if((PFCode=RARProcessFile(_rarFile, RAR_EXTRACT,(char*)[path UTF8String], NULL))!=0){
                [self _unrarCloseFile];
                ThrowRARException(PFCode);
                return NO;
            }
        }
        
        [self _unrarCloseFile];
        return YES;
    }else{
        return NO;
    }
    
}

-(NSData *) extractStream:(NSString *)aFile {
	
	size_t length = 0;
    
	int RHCode = 0, PFCode = 0;
	
	[self _unrarOpenFile:self.filename inMode:RAR_OM_EXTRACT withPassword:self.password];
	
	while ((RHCode = RARReadHeaderEx(_rarFile, header)) == 0) {
		NSString * filename = [NSString stringWithCString:header->FileName encoding:NSASCIIStringEncoding];
        
		if ([filename isEqualToString:aFile]) {
			length = header->UnpSize;
			break;
		}
		else {
			if ((PFCode = RARProcessFile(_rarFile, RAR_SKIP, NULL, NULL)) != 0) {
				[self _unrarCloseFile];
				return nil;
			}
		}
	}
	
	if (length == 0) { // archived file not found
		[self _unrarCloseFile];
		return nil;
	}
	
	UInt8 *buffer = new UInt8[length];
	UInt8 *callBackBuffer = buffer;
	
	RARSetCallback(_rarFile, CallbackProc, (long) &callBackBuffer);
	
	PFCode = RARProcessFile(_rarFile, RAR_TEST, NULL, NULL);
    
    [self _unrarCloseFile];
    
    ThrowRARException(PFCode);
    
    return [NSData dataWithBytes:buffer length:length];
}

-(BOOL) _unrarCloseFile {
    if (flags){
        delete flags;
        flags = NULL;
    }
    
	if (_rarFile){
        return RARCloseArchive(_rarFile);
    }else{
        return NO;
    }   
}

-(BOOL) unrarCloseFile {
	return [self _unrarCloseFile];
}


-(void) dealloc {
    self.filename = nil;
    self.password = nil;
	[super dealloc];
}

@end
