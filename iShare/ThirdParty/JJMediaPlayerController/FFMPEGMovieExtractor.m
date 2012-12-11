//
//  Video.m
//  iFrameExtractor
//
//  Created by lajos on 1/10/10.
//  Copyright 2010 www.codza.com. All rights reserved.
//

#import "FFMPEGMovieExtractor.h"
#import "Utilities.h"

@interface FFMPEGMovieExtractor (private)
-(void)convertFrameToRGB;
-(UIImage *)imageFromAVPicture:(AVPicture)pict width:(int)width height:(int)height;
-(void)savePicture:(AVPicture)pVideoFrame width:(int)width height:(int)height index:(int)iFrame;
-(void)setupScaler;
@end

@implementation FFMPEGMovieExtractor

@synthesize pAudioFrame;

-(void)setOutputWidth:(int)newValue {
	if (_outputWidth == newValue) return;
	_outputWidth = newValue;
	[self setupScaler];
}

-(void)setOutputHeight:(int)newValue {
	if (_outputHeight == newValue) return;
	_outputHeight = newValue;
	[self setupScaler];
}

-(UIImage *)currentImage {
	if (!pVideoFrame->data[0]) return nil;
	[self convertFrameToRGB];
	return [self imageFromAVPicture:picture width:_outputWidth height:_outputHeight];
}

-(NSData*)currentSound{
    return [NSData dataWithBytes:pAudioFrame->data[0] length:pAudioFrame->linesize[0]];
}

-(int)soundRate{
    return pAudioFrame->sample_rate;
}

-(double)duration {
	return (double)pFormatCtx->duration / AV_TIME_BASE;
}

-(double)currentTime {
    AVRational timeBase = pFormatCtx->streams[videoStream]->time_base;
    return packet.pts * (double)timeBase.num / timeBase.den;
}

-(int)sourceWidth {
	return pVideoCodecCtx->width;
}

-(int)sourceHeight {
	return pVideoCodecCtx->height;
}

-(id)initWithVideo:(NSString *)moviePath {
	if (!(self=[super init])) return nil;
 
    AVCodec* videoCodec;
    AVCodec* audioCodec;
		
    // Register all formats and codecs
    avcodec_register_all();
    av_register_all();
	
    // Open movie file
    if(avformat_open_input(&pFormatCtx, [moviePath cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL) != 0) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't open file\n");
        goto initError;
    }
	
    // Retrieve stream information
    if(avformat_find_stream_info(pFormatCtx,NULL) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't find stream information\n");
        goto initError;
    }
    
    // Find the best video stream
    if ((videoStream =  av_find_best_stream(pFormatCtx, AVMEDIA_TYPE_VIDEO, -1, -1, &videoCodec, 0)) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Cannot find a video stream in the input file\n");
        goto initError;
    }
    
    // Find the best audio stream 
    if ((audioStream = av_find_best_stream(pFormatCtx, AVMEDIA_TYPE_AUDIO, -1, -1, &audioCodec, 0)) < 0){
        av_log(NULL, AV_LOG_ERROR, "Cannot find a video stream in the input file\n");
        goto initError;
    }
	
    // Get a pointer to the codec context for the video stream
    pVideoCodecCtx = pFormatCtx->streams[videoStream]->codec;
    // Get a pointer to the codec context for the audio stream
    pAudioCodecCtx = pFormatCtx->streams[audioStream]->codec;
    // Find the decoder for the video stream
    videoCodec = avcodec_find_decoder(pVideoCodecCtx->codec_id);
    // Find the decoder for the audio stream
    audioCodec = avcodec_find_decoder(pAudioCodecCtx->codec_id);
    if(videoCodec == NULL || audioCodec == NULL) {
        av_log(NULL, AV_LOG_ERROR, "Unsupported codec!\n");
        goto initError;
    }
	
    // Open codec
    if(avcodec_open2(pVideoCodecCtx, videoCodec, NULL) < 0 || avcodec_open2(pAudioCodecCtx, audioCodec, NULL) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Cannot open video decoder\n");
        goto initError;
    }
	
    // Allocate video frame
    pVideoFrame = avcodec_alloc_frame();
    // Allocate audio frame
    pAudioFrame = avcodec_alloc_frame();
    
    //get width and height
	self.outputWidth = pVideoCodecCtx->width;
	self.outputHeight = pVideoCodecCtx->height;
			
	return self;
	
initError:
	return nil;
}


-(void)setupScaler {

	// Release old picture and scaler
	avpicture_free(&picture);
	sws_freeContext(img_convert_ctx);	
	
	// Allocate RGB picture
	avpicture_alloc(&picture, PIX_FMT_RGB24, _outputWidth, _outputHeight);
	
	// Setup scaler
	static int sws_flags =  SWS_FAST_BILINEAR;
	img_convert_ctx = sws_getContext(pVideoCodecCtx->width, 
									 pVideoCodecCtx->height,
									 pVideoCodecCtx->pix_fmt,
									 _outputWidth,
									 _outputHeight,
									 PIX_FMT_RGB24,
									 sws_flags, NULL, NULL, NULL);
	
}

-(void)seekTime:(double)seconds {
	AVRational timeBase = pFormatCtx->streams[videoStream]->time_base;
	int64_t targetFrame = (int64_t)((double)timeBase.den / timeBase.num * seconds);
	avformat_seek_file(pFormatCtx, videoStream, targetFrame, targetFrame, targetFrame, AVSEEK_FLAG_FRAME);
	avcodec_flush_buffers(pVideoCodecCtx);
    avcodec_flush_buffers(pAudioCodecCtx);
}

-(void)dealloc {
	// Free scaler
	sws_freeContext(img_convert_ctx);	

	// Free RGB picture
	avpicture_free(&picture);
    
    // Free the packet that was allocated by av_read_frame
    av_free_packet(&packet);
    // Free the YUV frame
    av_free(pVideoFrame);
	av_free(pAudioFrame);
    // Close the codec
    if (pVideoCodecCtx) avcodec_close(pVideoCodecCtx);
    if (pAudioCodecCtx) avcodec_close(pAudioCodecCtx);
    // Close the video file
    if (pFormatCtx) avformat_close_input(&pFormatCtx);

}

-(BOOL)stepFrame {
	// AVPacket packet;
    int frameFinished=0;

    while(!frameFinished && av_read_frame(pFormatCtx, &packet)>=0) {
        // Is this a packet from the video stream?
        if(packet.stream_index== videoStream) {
            // Decode video frame
            DebugLog(@"read video stream now");
            avcodec_decode_video2(pVideoCodecCtx, pVideoFrame, &frameFinished, &packet);
        }else if(packet.stream_index == audioStream){        // Is this a audioPacket from the audio stream?
            DebugLog(@"read audio stream now");
            avcodec_decode_audio4(pAudioCodecCtx, pAudioFrame, &frameFinished, &packet);
        }
	}
    
	return frameFinished!=0;
}

-(void)convertFrameToRGB {	
	sws_scale (img_convert_ctx, pVideoFrame->data, pVideoFrame->linesize,
			   0, pVideoCodecCtx->height,
			   picture.data, picture.linesize);	
}

-(UIImage *)imageFromAVPicture:(AVPicture)pict width:(int)width height:(int)height {
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
	CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, pict.data[0], pict.linesize[0]*height,kCFAllocatorNull);
	CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGImageRef cgImage = CGImageCreate(width, 
									   height, 
									   8, 
									   24, 
									   pict.linesize[0], 
									   colorSpace, 
									   bitmapInfo, 
									   provider, 
									   NULL, 
									   NO, 
									   kCGRenderingIntentDefault);
	CGColorSpaceRelease(colorSpace);
	UIImage *image = [UIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);
	CGDataProviderRelease(provider);
	CFRelease(data);
	
	return image;
}

-(void)savePPMPicture:(AVPicture)pict width:(int)width height:(int)height index:(int)iFrame {
    FILE *pFile;
	NSString *fileName;
    int  y;
	
	fileName = [Utilities documentsPath:[NSString stringWithFormat:@"image%04d.ppm",iFrame]];
    // Open file
    NSLog(@"write image file: %@",fileName);
    pFile=fopen([fileName cStringUsingEncoding:NSASCIIStringEncoding], "wb");
    if(pFile==NULL)
        return;
	
    // Write header
    fprintf(pFile, "P6\n%d %d\n255\n", width, height);
	
    // Write pixel data
    for(y=0; y<height; y++)
        fwrite(pict.data[0]+y*pict.linesize[0], 1, width*3, pFile);
	
    // Close file
    fclose(pFile);
}
//
//-(void)startSyncAudio{
//    
//    int buffedLen=0;
//    AVPacket packet;
//    int out_size = AVCODEC_MAX_AUDIO_FRAME_SIZE*1.5;
//    uint8_t * inbuf = (uint8_t *)malloc(out_size);
//    while (true) {
////        packet_queue_get(audioQueue, &packet, 1);
//        out_size = AVCODEC_MAX_AUDIO_FRAME_SIZE*1.5;
//        int len = avcodec_decode_audio4(pVideoCodecCtx, (short*)inbuf, &out_size, &packet);
//        if (len<0)
//        {
//            printf("Error while decoding.\n");
//            buffedLen=0;
//        }
//        if(out_size>0)
//        {
//            playAudio(inbuf ,out_size ,pVideoCodecCtx->sample_rate);
//        }
//    }
//}
//
//void playAudio(uint8_t * inbuf, int outSize, int sampleRate){
//    
//}

@end
