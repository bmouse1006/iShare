//
//  JJYUVDisplayView.m
//  iShare
//
//  Created by Jin Jin on 13-1-5.
//  Copyright (c) 2013年 Jin Jin. All rights reserved.
//

#import "JJYUVDisplayView.h"
#import <QuartzCore/QuartzCore.h>

#define MAX_PLANES 3

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

#pragma mark - define for YUV images

enum{
    UNIFORM_SAMPLE2D_Y = 0,
    UNIFORM_SAMPLE2D_U,
    UNIFORM_SAMPLE2D_V,
    NUMBER_OF_UNIFORMS
};

typedef struct YV12Image
{
    BYTE     *planeData[MAX_PLANES];
    int      planeSize[MAX_PLANES];
    unsigned stride[MAX_PLANES];
    unsigned width;
    unsigned height;
    unsigned flags;
    
    unsigned cshift_x; /* this is the chroma shift used */
    unsigned cshift_y;
} YV12Image;

typedef struct _YUVPLANE
{
    GLuint ID; //texture的ID
    
    unsigned texwidth;
    unsigned texheight;
    
    
}YUVPLANE;

typedef  YUVPLANE        YUVPLANES[MAX_PLANES];

typedef struct YUVBUFFER
{
    YV12Image image; // YUV源数据
    YUVPLANES  planes; // YUV对应的texture
}YUVBUFFER;

// attribute index
enum {
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD,
    NUM_ATTRIBUTES
};

@interface JJYUVDisplayView(){
    YUVBUFFER _yuvbuffer;
    
    uint _width;
    uint _height;
    
    GLuint _program;
    
    GLint uniforms[NUMBER_OF_UNIFORMS];
    
    GLuint _verticesArray;
    GLuint _verticesBuffer;
}

@property (nonatomic, strong) EAGLContext* context;

@end

@implementation JJYUVDisplayView

static const GLfloat verticesData[] = {
    -1.0f, -1.0f, 0.0f, 1.0f,
    1.0f, -1.0f, 1.0f, 1.0f,
    -1.0f, 1.0f, 0.0f, 0.0f,
    1.0f, 1.0f, 1.0f, 0.0f
};

-(void)dealloc{
    [self tearDownGL];
    [self freeYUVBuffer];
}

-(id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self){
        //初始化
        [self setupGL];
        [self render];
        
        if ([self loadShaders] == NO){
            self = nil;
        }
        
        self.delegate = self;
    }
    
    return self;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    @synchronized(self.context){
        glClear(GL_COLOR_BUFFER_BIT);
        glUseProgram(_program);
        //将3个YUV分量绑定到texture
        [self bindTextureFromBuffer:&_yuvbuffer];
        [self drawPicture];
    }
}

-(void)drawPicture{
    //根据绑定好的顶点和纹理绘制OpenGL
    glBindVertexArrayOES(_verticesArray);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

#pragma mark - frame buffer create and release
-(void)freeYUVBuffer{
    for (int i = 0; i < 3; i++)
    {
        if (_yuvbuffer.image.planeData[i]){
            free(_yuvbuffer.image.planeData[i]);
            _yuvbuffer.image.planeData[i] = NULL;
        }
    }
}

- (void)YUVBufferInitWithWidth:(uint)width height:(uint)height
{
    YV12Image* im = &(_yuvbuffer.image);      // YUV对应的参数
//    YUVPLANES* planes = &(_yuvbuffer.planes);  // YUV对应的纹理
    
    _width = width;
    _height = height;
    
    im->width = width;
    im->height = height;
    im->cshift_x = 1;
    im->cshift_y = 1;
    
    im->stride[0] = im->width;
    im->stride[1] = im->width >> im->cshift_x;
    im->stride[2] = im->width >> im->cshift_x;
    
    im->planeSize[0] = im->stride[0] * im->height;
    im->planeSize[1] = im->stride[1] * (im->height >> im->cshift_y);
    im->planeSize[2] = im->stride[2] * (im->height >> im->cshift_y);
    
    for (int i = 0; i < 3; i++)
    {
        im->planeData[i] = (BYTE*)malloc(im->planeSize[i]);
        int shift = (i == 0) ? 0 : 1;
        _yuvbuffer.planes[i].texwidth = (im->width) >> shift;
        _yuvbuffer.planes[i].texheight = (im->height) >> shift;
    }
}

-(void)setVideoPicture:(YUVVideoPicture*)picture{
    @synchronized(self.context){
        if (_width != picture->width || _height != picture->height){
            [self freeYUVBuffer];
            [self YUVBufferInitWithWidth:picture->width height:picture->height];
        }
        
        [self copyYUVVectors:picture];
        [self display];
    }
}
#pragma mark - GL setup and tear down
-(void)tearDownGL{
    [EAGLContext setCurrentContext:self.context];
    
    for (int i = 0; i<3;i++){
        glDeleteTextures(1, &(_yuvbuffer.planes[i].ID));
        _yuvbuffer.planes[i].ID = 0;
    }
    
    glDeleteBuffers(1, &_verticesBuffer);
    glDeleteVertexArraysOES(1, &_verticesArray);
     
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

- (void)setupGL {
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    self.context = [[EAGLContext alloc] initWithAPI:api];
    self.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self createVertexBuffers];
}

-(void)createVertexBuffers{
    [EAGLContext setCurrentContext:self.context];
    
    glGenVertexArraysOES(1, &_verticesArray);
    glBindVertexArrayOES(_verticesArray);
    
    glGenBuffers(1, &_verticesBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _verticesBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(verticesData), verticesData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 16, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, 16, BUFFER_OFFSET(8));
    
    glBindVertexArrayOES(0);
    
}

- (void)render {
    //全黑
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
}

#pragma mark - shaders
- (BOOL) compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
	GLint status;
	const GLchar *source;
	
	source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
	if (!source)
	{
		NSLog(@"Failed to load vertex shader");
		return FALSE;
	}
	
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
	
#if defined(DEBUG)
	GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
	{
		glDeleteShader(*shader);
		return FALSE;
	}
	
	return TRUE;
}

- (BOOL) linkProgram:(GLuint)prog
{
	GLint status;
	
	glLinkProgram(prog);
    
#if defined(DEBUG)
	GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
		return FALSE;
	
	return TRUE;
}

#if defined(DEBUG)
- (BOOL) validateProgram:(GLuint)prog
{
	GLint logLength, status;
	
	glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0)
		return FALSE;
	
	return TRUE;
}
#endif

- (BOOL) loadShaders
{
    GLuint vertShader, fragShader;
	NSString *vertShaderPathname, *fragShaderPathname;
    [EAGLContext setCurrentContext:self.context];
    // create shader program
    _program = glCreateProgram();
	
    // create and compile vertex shader
	vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"process" ofType:@"vsh"];
	if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname])
	{
		NSLog(@"Failed to compile vertex shader");
		return FALSE;
	}
	
    // create and compile fragment shader
	fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"process" ofType:@"fsh"];
	if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname])
	{
		NSLog(@"Failed to compile fragment shader");
		return FALSE;
	}
    
    // attach vertex shader to program
    glAttachShader(_program, vertShader);
    
    // attach fragment shader to program
    glAttachShader(_program, fragShader);
    
    // bind attribute locations
    // this needs to be done prior to linking
    glBindAttribLocation(_program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIB_TEXCOORD, "textureCoordinate");
    
    // link program
	if (![self linkProgram:_program])
	{
		NSLog(@"Failed to link program: %d", _program);
		return FALSE;
	}
    
    //获取shader中uniform变量的位置
    uniforms[UNIFORM_SAMPLE2D_Y] = glGetUniformLocation(_program, "SamplerY");
    uniforms[UNIFORM_SAMPLE2D_U] = glGetUniformLocation(_program, "SamplerU");
    uniforms[UNIFORM_SAMPLE2D_V] = glGetUniformLocation(_program, "SamplerV");
    
    // release vertex and fragment shaders
    if (vertShader)
		glDeleteShader(vertShader);
    if (fragShader)
		glDeleteShader(fragShader);
    
	return TRUE;
}

//YUV分量的抽取
//抽取到_yuvbuffer中
-(void)copyYUVVectors:(YUVVideoPicture*)pic
{
    YV12Image* img = &(_yuvbuffer.image);
    BYTE *s = pic->data[0];
    BYTE *d = img->planeData[0];
    int w = pic->width;
    int h = pic->height;
    if ( (w == pic->linesize[0]) && ((unsigned int) pic->linesize[0] == img->stride[0]))
    {
        memcpy(d, s, w*h);
    }
    else
    {
        for (int y = 0; y < h; y++)
        {
            memcpy(d, s, w);
            s += pic->linesize[0]; // iLineSize padding
            d += img->stride[0];
        }
    }
    s = pic->data[1];
    d = img->planeData[1];
    w = pic->width >> 1;
    h = pic->height >> 1;
    if ( (w == pic->linesize[1]) && ((unsigned int) pic->linesize[1] == img->stride[1]))
    {
        memcpy(d, s, w*h);
    }
    else
    {
        for (int y = 0; y < h; y++)
        {
            memcpy(d, s, w);
            s += pic->linesize[1];
            d += img->stride[1];
        }
    }
    s = pic->data[2];
    d = img->planeData[2];
    if ((w==pic->linesize[2]) && ((unsigned int) pic->linesize[2]==img->stride[2]))
    {
        memcpy(d, s, w*h);
    }
    else
    {
        for (int y = 0; y < h; y++)
        {
            memcpy(d, s, w);
            s += pic->linesize[2];
            d += img->stride[2];
        }
    }
}

#pragma mark - bind texture
-(void)bindTextureFromBuffer:(YUVBUFFER*)buffer{
    
    [EAGLContext setCurrentContext:self.context];
    
    for (int i = 0; i<3; i++){
        //删除原来已绑定的纹理
        glDeleteTextures(1, &(buffer->planes[i].ID));
        glActiveTexture(GL_TEXTURE0+i);
        //生成纹理
        glGenTextures(1, &(buffer->planes[i].ID));
        //绑定至当前激活的纹理单元
        glBindTexture(GL_TEXTURE_2D, buffer->planes[i].ID);
        /* 设置纹理参数 */
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);//用于大小非2次幂的纹理
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        //将纹理图像发送给GPU，绑定纹理图像至当前激活纹理单元
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, buffer->planes[i].texwidth, buffer->planes[i].texheight, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, buffer->image.planeData[i]);
        //绑定uniform变量到当前激活纹理单元
        glUniform1i(uniforms[i], i);
    }
}

@end
