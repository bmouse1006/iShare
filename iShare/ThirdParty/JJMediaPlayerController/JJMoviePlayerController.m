//
//  JJMoviePlayerController.m
//  iShare
//
//  Created by Jin Jin on 12-12-5.
//  Copyright (c) 2012年 Jin Jin. All rights reserved.
//

#import "SDL.h"
#import "SDL_audio.h"
#import "SDL_video.h"

#import "JJMoviePlayerController.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"


#define SDL_AUDIO_BUFFER_SIZE 1024

#define MAX_AUDIOQ_SIZE (5 * 16 * 1024)
#define MAX_VIDEOQ_SIZE (5 * 256 * 1024)

#define FF_ALLOC_EVENT   (SDL_USEREVENT)
#define FF_REFRESH_EVENT (SDL_USEREVENT + 1)
#define FF_QUIT_EVENT (SDL_USEREVENT + 2)
#define FF_PAUSE_EVENT (SDL_USEREVENT + 3)
#define VIDEO_PICTURE_QUEUE_SIZE 1
#define SDL_AUDIO_BUFFER_SIZE 1024

static int sws_flags = SWS_BICUBIC;


typedef struct PacketQueue
{
	AVPacketList *first_pkt, *last_pkt;
	int nb_packets;
	int size;
	SDL_mutex *mutex;
	SDL_cond *cond;
} PacketQueue;

typedef struct VideoPicture
{
	SDL_Overlay *bmp;
	int width, height; /* source height & width */
	int allocated;
} VideoPicture;

typedef struct VideoState
{
	AVFormatContext *pFormatCtx;
	int             videoStream, audioStream;
	AVStream        *audio_st;
	PacketQueue     audioq;
	uint8_t         audio_buf[(AVCODEC_MAX_AUDIO_FRAME_SIZE * 3) / 2];
	unsigned int    audio_buf_size;
	unsigned int    audio_buf_index;
	AVPacket        audio_pkt;
	uint8_t         *audio_pkt_data;
	int             audio_pkt_size;
	AVStream        *video_st;
	PacketQueue     videoq;
    
	VideoPicture    pictq[VIDEO_PICTURE_QUEUE_SIZE];
	int             pictq_size, pictq_rindex, pictq_windex;
	SDL_mutex       *pictq_mutex;
	SDL_cond        *pictq_cond;
    
	SDL_Thread      *parse_tid;
	SDL_Thread      *video_tid;
    
	char            filename[1024];
	int             quit;
} VideoState;

SDL_Surface     *screen;

/* Since we only have one decoding thread, the Big Struct
 can be global in case we need it. */
VideoState *global_video_state;

void PushEvent(Uint32 type, void* data){
    SDL_Event event;
    event.type = type;
    event.user.data1 = data;
    SDL_PushEvent(&event);
}

void packet_queue_init(PacketQueue *q)
{
	memset(q, 0, sizeof(PacketQueue));
	q->mutex = SDL_CreateMutex();
	q->cond = SDL_CreateCond();
}
int packet_queue_put(PacketQueue *q, AVPacket *pkt)
{
	AVPacketList *pkt1;
	if(av_dup_packet(pkt) < 0)
	{
		return -1;
	}
	pkt1 = (AVPacketList *)av_malloc(sizeof(AVPacketList));
	if (!pkt1)
		return -1;
	pkt1->pkt = *pkt;
	pkt1->next = NULL;
	SDL_LockMutex(q->mutex);
	if (!q->last_pkt)
		q->first_pkt = pkt1;
	else
		q->last_pkt->next = pkt1;
	q->last_pkt = pkt1;
	q->nb_packets++;
	q->size += pkt1->pkt.size;
	SDL_CondSignal(q->cond);
	SDL_UnlockMutex(q->mutex);
	return 0;
}
static int packet_queue_get(PacketQueue *q, AVPacket *pkt, int block)
{
	AVPacketList *pkt1;
	int ret;
	SDL_LockMutex(q->mutex);
	for(;;)
	{
		if(global_video_state->quit)
		{
			ret = -1;
			break;
		}
		pkt1 = q->first_pkt;
		if (pkt1)
		{
			q->first_pkt = pkt1->next;
			if (!q->first_pkt)
				q->last_pkt = NULL;
			q->nb_packets--;
			q->size -= pkt1->pkt.size;
			*pkt = pkt1->pkt;
			av_free(pkt1);
			ret = 1;
			break;
		}
		else if (!block)
		{
			ret = 0;
			break;
		}
		else
		{
			SDL_CondWait(q->cond, q->mutex);
		}
	}
	SDL_UnlockMutex(q->mutex);
	return ret;
}

int audio_decode_frame(VideoState *is, uint8_t *audio_buf, int buf_size)
{
	int len1, data_size;
	AVPacket *pkt = &is->audio_pkt;
    
	for(;;)
	{
		while(is->audio_pkt_size > 0)
		{
			data_size = buf_size;
            AVFrame* frame = NULL;
            int finished = 0;
            len1 = avcodec_decode_audio4(is->audio_st->codec, frame, &finished, &(is->audio_pkt));
            /*			len1 = avcodec_decode_audio2(is->audio_st->codec,
                                         (int16_t *)audio_buf, &data_size,
                                         is->audio_pkt_data, is->audio_pkt_size);
             */
			if(len1 < 0)
			{
				/* if error, skip frame */
				is->audio_pkt_size = 0;
				break;
			}
			is->audio_pkt_data += len1;
			is->audio_pkt_size -= len1;
			if(data_size <= 0)
			{
				/* No data yet, get more frames */
				continue;
			}
			/* We have data, return it and come back for more later */
			return data_size;
		}
		if(pkt->data)
			av_free_packet(pkt);
        
		if(is->quit)
		{
			return -1;
		}
		/* next packet */
		if(packet_queue_get(&is->audioq, pkt, 1) < 0)
		{
			return -1;
		}
		is->audio_pkt_data = pkt->data;
		is->audio_pkt_size = pkt->size;
	}
}

void audio_callback(void *userdata, Uint8 *stream, int len)
{
	VideoState *is = (VideoState *)userdata;
	int len1, audio_size;
    
	while(len > 0)
	{
		if(is->audio_buf_index >= is->audio_buf_size)
		{
			/* We have already sent all our data; get more */
			audio_size = audio_decode_frame(is, is->audio_buf, sizeof(is->audio_buf));
			if(audio_size < 0)
			{
				/* If error, output silence */
				is->audio_buf_size = 1024;
				memset(is->audio_buf, 0, is->audio_buf_size);
			}
			else
			{
				is->audio_buf_size = audio_size;
			}
			is->audio_buf_index = 0;
		}
		len1 = is->audio_buf_size - is->audio_buf_index;
		if(len1 > len)
			len1 = len;
		memcpy(stream, (uint8_t *)is->audio_buf + is->audio_buf_index, len1);
		len -= len1;
		stream += len1;
		is->audio_buf_index += len1;
	}
}


static Uint32 sdl_refresh_timer_cb(Uint32 interval, void *opaque)
{
	//printf("sdl_refresh_timer_cb called:interval--%d/n",interval);
    PushEvent(FF_REFRESH_EVENT, opaque);//派发FF_REFRESH_EVENT事件
	return 0; /* 0 means stop timer */
}

/* schedule a video refresh in 'delay' ms */
static void schedule_refresh(VideoState *is, int delay)
{
	//printf("schedule_refresh called:delay--%d/n",delay);
	SDL_AddTimer(delay, sdl_refresh_timer_cb, is);		//sdl_refresh_timer_cb函数在延时delay毫秒后，只会被执行一次，is是sdl_refresh_timer_cb的参数
}

void video_display(VideoState *is)
{
	//printf("video_display called/n");
	SDL_Rect rect;
	VideoPicture *vp;
//	AVPicture pict;
	float aspect_ratio;
	int w, h, x, y;
    
	vp = &is->pictq[is->pictq_rindex];
	if(vp->bmp)
	{
		if(is->video_st->codec->sample_aspect_ratio.num == 0)
		{
			aspect_ratio = 0;
		}
		else
		{
			aspect_ratio = av_q2d(is->video_st->codec->sample_aspect_ratio) *
            is->video_st->codec->width / is->video_st->codec->height;
		}
		if(aspect_ratio <= 0.0)		//aspect_ratio 宽高比
		{
			aspect_ratio = (float)is->video_st->codec->width /
            (float)is->video_st->codec->height;
		}
		h = screen->h;
		w = ((int)(h * aspect_ratio)) & -3;
		if(w > screen->w)
		{
			w = screen->w;
			h = ((int)(w / aspect_ratio)) & -3;
		}
		x = (screen->w - w) / 2;
		y = (screen->h - h) / 2;
        
		rect.x = x;
		rect.y = y;
		rect.w = w;
		rect.h = h;
		SDL_DisplayYUVOverlay(vp->bmp, &rect);
	}
}

void video_refresh_timer(void *userdata)
{
	VideoState *is = (VideoState *)userdata;
	VideoPicture *vp;
    
	if(is->video_st)
	{
		if(is->pictq_size == 0)
		{
			schedule_refresh(is, 1);
		}
		else
		{
			vp = &is->pictq[is->pictq_rindex];
			/* Now, normally here goes a ton of code
             about timing, etc. we're just going to
             guess at a delay for now. You can
             increase and decrease this value and hard code
             the timing - but I don't suggest that ;)
             We'll learn how to do it for real later.
             */
			schedule_refresh(is, 80);
            
			/* show the picture! */
			video_display(is);
            
			/* update queue for next picture! */
			if(++is->pictq_rindex == VIDEO_PICTURE_QUEUE_SIZE)
			{
				is->pictq_rindex = 0;
			}
			SDL_LockMutex(is->pictq_mutex);
			is->pictq_size--;
			SDL_CondSignal(is->pictq_cond);
			SDL_UnlockMutex(is->pictq_mutex);
		}
	}
	else
	{
		schedule_refresh(is, 100);
	}
}

void alloc_picture(void *userdata)
{
	VideoState *is = (VideoState *)userdata;
	VideoPicture *vp;
    
	vp = &is->pictq[is->pictq_windex];
	if(vp->bmp)
	{
		// we already have one make another, bigger/smaller
		SDL_FreeYUVOverlay(vp->bmp);
	}
	// Allocate a place to put our YUV image on that screen
	vp->bmp = SDL_CreateYUVOverlay(is->video_st->codec->width,
                                   is->video_st->codec->height,
                                   SDL_YV12_OVERLAY,
                                   screen);
	vp->width = is->video_st->codec->width;
	vp->height = is->video_st->codec->height;
    
	SDL_LockMutex(is->pictq_mutex);
	vp->allocated = 1;
	SDL_CondSignal(is->pictq_cond);
	SDL_UnlockMutex(is->pictq_mutex);
    
}

int queue_picture(VideoState *is, AVFrame *pFrame)
{
	//printf("queue_picture called/n");
	VideoPicture *vp;
	int dst_pix_fmt;
	AVPicture pict;
	static struct SwsContext *img_convert_ctx;
	if (img_convert_ctx == NULL)
	{
        img_convert_ctx = sws_getContext(is->video_st->codec->width, is->video_st->codec->height,
                                         is->video_st->codec->pix_fmt,
                                         is->video_st->codec->width, is->video_st->codec->height,
                                         PIX_FMT_YUV420P,
                                         sws_flags, NULL, NULL, NULL);
        if (img_convert_ctx == NULL)
		{
            fprintf(stderr, "Cannot initialize the conversion context/n");
            PushEvent(FF_QUIT_EVENT, is);
            return 0;
        }
    }
    
	/* wait until we have space for a new pic */
	SDL_LockMutex(is->pictq_mutex);
	while(is->pictq_size >= VIDEO_PICTURE_QUEUE_SIZE &&
          !is->quit)
	{
		SDL_CondWait(is->pictq_cond, is->pictq_mutex);
	}
	SDL_UnlockMutex(is->pictq_mutex);
    
	if(is->quit)
		return -1;
    
	// windex is set to 0 initially
	vp = &is->pictq[is->pictq_windex];
	
	/* allocate or resize the buffer! */
	if(!vp->bmp ||
       vp->width != is->video_st->codec->width ||
       vp->height != is->video_st->codec->height)
	{
        
		vp->allocated = 0;
		/* we have to do it in the main thread */
        PushEvent(FF_ALLOC_EVENT, is);
        
		/* wait until we have a picture allocated */
		SDL_LockMutex(is->pictq_mutex);
		while(!vp->allocated && !is->quit)
		{
			SDL_CondWait(is->pictq_cond, is->pictq_mutex);	//没有得到消息时解锁，得到消息后加锁，和SDL_CondSignal配对使用
		}
		SDL_UnlockMutex(is->pictq_mutex);
		if(is->quit)
		{
			return -1;
		}
	}
	/* We have a place to put our picture on the queue */
    
	if(vp->bmp)
	{
		SDL_LockYUVOverlay(vp->bmp);
		dst_pix_fmt = PIX_FMT_YUV420P;
		/* point pict at the queue */
        
		pict.data[0] = vp->bmp->pixels[0];
		pict.data[1] = vp->bmp->pixels[2];
		pict.data[2] = vp->bmp->pixels[1];
        
		pict.linesize[0] = vp->bmp->pitches[0];
		pict.linesize[1] = vp->bmp->pitches[2];
		pict.linesize[2] = vp->bmp->pitches[1];
        
		// Convert the image into YUV format that SDL uses
		sws_scale(img_convert_ctx, pFrame->data, pFrame->linesize, 0, is->video_st->codec->height, pict.data, pict.linesize);
		SDL_UnlockYUVOverlay(vp->bmp);
		/* now we inform our display thread that we have a pic ready */
		if(++is->pictq_windex == VIDEO_PICTURE_QUEUE_SIZE)
		{
			is->pictq_windex = 0;
		}
		SDL_LockMutex(is->pictq_mutex);
		is->pictq_size++;
		SDL_UnlockMutex(is->pictq_mutex);
	}
	return 0;
}

int video_thread(void *arg)
{
	//printf("video_thread called");
	VideoState *is = (VideoState *)arg;
	AVPacket pkt1, *packet = &pkt1;
	int len1, frameFinished;
	AVFrame *pFrame;
    
	pFrame = avcodec_alloc_frame();
    
	for(;;)
	{
		if(packet_queue_get(&is->videoq, packet, 1) < 0)
		{
			// means we quit getting packets
			break;
		}
		// Decode video frame
		len1 = avcodec_decode_video2(is->video_st->codec, pFrame, &frameFinished, packet);
        
		// Did we get a video frame?
		if(frameFinished)
		{
			if(queue_picture(is, pFrame) < 0)
			{
				break;
			}
		}
		av_free_packet(packet);
	}
	av_free(pFrame);
	return 0;
}

int decode_interrupt_cb(void* opaque)
{
	return (global_video_state && global_video_state->quit);
}

int decode_thread(void *arg)
{
    VideoState* is = (VideoState*)arg;
	AVPacket pkt1, *packet=&pkt1;
        
	// main decode loop
	for(;;)
	{
		if(is->quit)
		{
			break;
		}
		// seek stuff goes here
		if(is->audioq.size > MAX_AUDIOQ_SIZE ||
           is->videoq.size > MAX_VIDEOQ_SIZE)
		{
            SDL_Delay(10);
            continue;
		}
		if(av_read_frame(is->pFormatCtx, packet) < 0)
		{
			if(is->pFormatCtx->pb->error == 0)
			{
				SDL_Delay(100); /* no error; wait for user input */
				continue;
			}
			else
			{
				break;
			}
		}
		// Is this a packet from the video stream?
		if(packet->stream_index == is->videoStream)
		{
			packet_queue_put(&is->videoq, packet);
		}
		else if(packet->stream_index == is->audioStream)
		{
			packet_queue_put(&is->audioq, packet);
		}
		else
		{
			av_free_packet(packet);
		}
	}
	/* all done - wait for it */
	while(!is->quit)
	{
		SDL_Delay(100);
	}

    PushEvent(FF_QUIT_EVENT, is);
    
    return 0;
}

@interface JJMoviePlayerController (){
	AVCodecContext *pVideoCodecCtx;
	AVCodecContext *pAudioCodecCtx;
    NSTimeInterval seekTime;
    VideoState      *is;
    
    BOOL _prepared;
}

@property (nonatomic, copy) NSString* streamPath;

@property (nonatomic, strong) UIView* _internalView;
@property (nonatomic, strong) UIView* _internalBackgroundView;
@property (nonatomic, strong) UIView* _displayView;

@property (nonatomic, readonly) CGFloat outputWidth;
@property (nonatomic, readonly) CGFloat outputHeight;

@property (nonatomic, strong) NSThread* thread;

@end

@implementation JJMoviePlayerController

#pragma mark - getter and setter
-(CGSize)natrualSize{
    return CGSizeMake(pVideoCodecCtx->width, pVideoCodecCtx->height);
}

-(NSTimeInterval)playableDuration{
    return 1;
}

-(CGFloat)outputHeight{
    return self._displayView.frame.size.height;
}

-(CGFloat)outputWidth{
    return self._displayView.frame.size.width;
}

-(UIView*)view{
    return self._internalView;
}

-(UIView*)backgroundView{
    return self._internalBackgroundView;
}

-(void)dealloc{
    [self ffmpegAndScaler_release];
    [self SDL_release];
}

/**
 init of JJMoviePlayerController with file path
 @param filePath
 @return id
 @exception nil
 */
-(id)initWithFilepath:(NSString*)filePath{
    self = [super init];
    if (self){
        [self createViews];
        self.streamPath = filePath;
        self.initialPlaybackTime = 0.0;
        is = (VideoState *)av_mallocz(sizeof(VideoState));
        strcpy(is->filename, [filePath cStringUsingEncoding:NSUTF8StringEncoding]);
        is->pictq_mutex = SDL_CreateMutex();
        is->pictq_cond = SDL_CreateCond();
        is->videoStream=-1;
        is->audioStream=-1;
        
        global_video_state = is;
    }
    
    return self;
}

/**
 init of JJMoviePlayerController with input stream
 @param input stream
 @return id
 @exception nil
 */
-(id)initWithInputStream:(NSInputStream*)inputStream{
    self = [super init];
    if (self){

    }
    
    return self;
}

-(void)seekTime:(double)seconds {
	AVRational timeBase = is->video_st->time_base;
	int64_t targetFrame = (int64_t)((double)timeBase.den / timeBase.num * seconds);
	avformat_seek_file(is->pFormatCtx, is->videoStream, targetFrame, targetFrame, targetFrame, AVSEEK_FLAG_FRAME);
	avcodec_flush_buffers(pVideoCodecCtx);
    avcodec_flush_buffers(pAudioCodecCtx);
}

#pragma mark - create views
/**
 create views, including display view, background view and overall view
 @param nil
 @return nil
 @exception nil
 */
-(void)createViews{
    self._internalView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self._internalBackgroundView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self._displayView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
}

#pragma mark - ffmpeg and SDL init/dealloc
/**
 init ffmpeg
 @param nil
 @return success or not
 @exception nil
 */
-(BOOL)ffmpeg_init{
	AVFormatContext *pFormatCtx;
    AVDictionary* opt = NULL;
    
    // Register all formats and codecs
    avcodec_register_all();
    av_register_all();
    
	int video_index = -1;
	int audio_index = -1;
    
	// Open video file
    if (avformat_open_input(&pFormatCtx, is->filename, NULL, NULL) != 0){
		return -1; // Couldn't open file
    }
    // will interrupt blocking functions if we quit!
    pFormatCtx->interrupt_callback.callback = decode_interrupt_cb;
    pFormatCtx->interrupt_callback.opaque = NULL;
    
	is->pFormatCtx = pFormatCtx;
    
	// Retrieve stream information
    if (avformat_find_stream_info(pFormatCtx, &opt) < 0){
        return NO;
    } // Couldn't find stream information
    
	// Dump information about file onto standard error
	av_dump_format(pFormatCtx, 0, is->filename, 0);
    
    // Find the best video stream
    if ((video_index =  av_find_best_stream(pFormatCtx, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0)) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Cannot find a video stream in the input file\n");
        return NO;
    }
    
    // Find the best audio stream
    if ((audio_index = av_find_best_stream(pFormatCtx, AVMEDIA_TYPE_AUDIO, -1, -1, NULL, 0)) < 0){
        av_log(NULL, AV_LOG_ERROR, "Cannot find a video stream in the input file\n");
        return NO;
    }
    
	if(audio_index >= 0)
	{
		[self stream_component_open:audio_index];
	}
	if(video_index >= 0)
	{
        [self stream_component_open:video_index];
	}
    
	if(is->videoStream < 0 || is->audioStream < 0)
	{
		NSLog(@"%s: could not open codecs/n", is->filename);
        PushEvent(FF_QUIT_EVENT, is);
        
        return NO;
	}
		
    // Get a pointer to the codec context for the video stream
    pVideoCodecCtx = is->video_st->codec;
    // Get a pointer to the codec context for the audio stream
    pAudioCodecCtx = is->audio_st->codec;
    
    return YES;
}
//release ffmpeg
-(void)ffmpegAndScaler_release{
    // Close the codec
    if (pVideoCodecCtx) avcodec_close(pVideoCodecCtx);
    if (pAudioCodecCtx) avcodec_close(pAudioCodecCtx);
    // Close the video file
    if (is->pFormatCtx) avformat_close_input(&(is->pFormatCtx));
}

/**
 init SDL
 @param nil
 @return success or not
 @exception nil
 */
-(BOOL)SDL_init{
    SDL_Init(SDL_INIT_VIDEO|SDL_INIT_AUDIO|SDL_INIT_TIMER);
    SDL_DisplayMode fullscreen_mode;
    SDL_zero( fullscreen_mode );
    
    fullscreen_mode.format = SDL_PIXELFORMAT_RGB24;
    CGSize displaySize = self._displayView.frame.size;
    SDL_Window* m_nWindowID = SDL_CreateWindow(
                                   [@"JJMoviePlayerController" cStringUsingEncoding:NSUTF8StringEncoding],
                                   SDL_WINDOWPOS_UNDEFINED,
                                   SDL_WINDOWPOS_UNDEFINED,
                                   displaySize.width,
                                   displaySize.height,
                                   SDL_WINDOW_SHOWN | SDL_WINDOW_OPENGL );
    
    SDL_SetWindowDisplayMode( m_nWindowID, &fullscreen_mode );
//    SDL_SelectVideoDisplay(0);
    
    return YES;
}
//release SDL
-(void)SDL_release{
    SDL_Quit();
}

#pragma mark - prepare to play
/**
 Getting prepared for playing
 locate to the correct time
 @param nil
 @return nil
 @exception nil
 */
-(void)prepareToPlay{
    //init ffmpeg and SDL
    if (_prepared == NO){
        if ([self ffmpeg_init] == NO || [self SDL_init] == NO){
            NSLog(@"ffmpeg or SDL init failed");
            return;
        }
        //create and run decode thread
        is->parse_tid = SDL_CreateThread(decode_thread, "decode thread", is);
        
        if(!is->parse_tid)
        {
            av_free(is);
            return;
        }
        //create event mornitor thread
        self.thread = [[NSThread alloc] initWithTarget:self selector:@selector(eventMonitorLoop) object:nil];
        [self.thread start];
        _prepared = YES;
    }
    //demux video and audio stream
    //get them ready for play
    [self seekTime:self.initialPlaybackTime];
}

#pragma mark - play back control
-(void)play{
    //read video/audio/subtitle stream and play
    schedule_refresh(is, 40);
}

-(void)stop{
    
}

-(void)pause{
    PushEvent(FF_PAUSE_EVENT, NULL);
}

#pragma mark - thread loop
-(void)eventMonitorLoop{
    SDL_Event event;
    while([NSThread currentThread].isCancelled == NO)
	{
		SDL_WaitEvent(&event);
		switch(event.type)
		{
            case FF_QUIT_EVENT:
                NSLog(@"FF_QUIT_EVENT recieved");
            case SDL_QUIT:
                NSLog(@"SDL_QUIT recieved");
                is->quit = 1;
                SDL_Quit();
                return;
                break;
            case FF_ALLOC_EVENT:
                alloc_picture(event.user.data1);
                break;
            case FF_REFRESH_EVENT:
                video_refresh_timer(event.user.data1);
                break;
            case FF_PAUSE_EVENT:
                break;
            default:
                break;
		}
	}
}

#pragma mark - open stream
-(int)stream_component_open:(int)stream_index{
	AVFormatContext *pFormatCtx = is->pFormatCtx;
	AVCodecContext *codecCtx;
	AVCodec *codec;
	SDL_AudioSpec wanted_spec, spec;
    
	if(stream_index < 0 || stream_index >= pFormatCtx->nb_streams)
	{
		return -1;
	}
    
	// Get a pointer to the codec context for the video stream
	codecCtx = pFormatCtx->streams[stream_index]->codec;
    
	if(codecCtx->codec_type == AVMEDIA_TYPE_AUDIO)
	{
		// Set audio settings from codec info
		wanted_spec.freq = codecCtx->sample_rate;
		wanted_spec.format = AUDIO_S16SYS;
		wanted_spec.channels = codecCtx->channels;
		wanted_spec.silence = 0;
		wanted_spec.samples = SDL_AUDIO_BUFFER_SIZE;
		wanted_spec.callback = audio_callback;
		wanted_spec.userdata = is;
        
		if(SDL_OpenAudio(&wanted_spec, &spec) < 0)
		{
			fprintf(stderr, "SDL_OpenAudio: %s/n", SDL_GetError());
			return -1;
		}
	}
	codec = avcodec_find_decoder(codecCtx->codec_id);
    AVDictionary* opt = NULL;
	if(!codec || (avcodec_open2(codecCtx, codec, &opt) < 0))
	{
		fprintf(stderr, "Unsupported codec!/n");
		return -1;
	}
    
	switch(codecCtx->codec_type)
	{
        case AVMEDIA_TYPE_AUDIO:
            is->audioStream = stream_index;
            is->audio_st = pFormatCtx->streams[stream_index];
            is->audio_buf_size = 0;
            is->audio_buf_index = 0;
            memset(&is->audio_pkt, 0, sizeof(is->audio_pkt));
            packet_queue_init(&is->audioq);
            SDL_PauseAudio(0);
            break;
        case AVMEDIA_TYPE_VIDEO:
            is->videoStream = stream_index;
            is->video_st = pFormatCtx->streams[stream_index];
            
            packet_queue_init(&is->videoq);
            is->video_tid = SDL_CreateThread(video_thread, "video thread", is);
            break;
        default:
            break;
	}
    
    return 0;
}

@end
