//
//  MDAudioPlayerTableViewCell.m
//  MDAudioPlayerSample
//
//  Created by Matt Donnelly on 04/08/2010.
//  Copyright 2010 Matt Donnelly. All rights reserved.
//

#import "MDAudioPlayerTableViewCell.h"


@interface MDTableViewCellView : UIView
@end

@implementation MDTableViewCellView

- (void)drawRect:(CGRect)r
{
	[(MDAudioPlayerTableViewCell *)[self superview] drawContentView:r];
}

@end


@implementation MDAudioPlayerTableViewCell

@synthesize title;
@synthesize number;
@synthesize duration;
@synthesize isEven;
@synthesize isSelectedIndex;

static UIFont *textFont = nil;

+ (void)initialize
{
	if (self == [MDAudioPlayerTableViewCell class])
	{
		textFont = [UIFont boldSystemFontOfSize:15];
	}
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) 
	{
		contentView = [[MDTableViewCellView alloc] initWithFrame:CGRectZero];
		contentView.opaque = NO;
		[self addSubview:contentView];
	}
	
	return self;
}


- (void)setTitle:(NSString *)s
{
	title = [s copy];
	[self setNeedsDisplay]; 
}

- (void)setNumber:(NSString *)s
{
	number = [s copy];
	[self setNeedsDisplay]; 
}

- (void)setDuration:(NSString *)s
{
	duration = [s copy];
	[self setNeedsDisplay]; 
}

- (void)setIsSelectedIndex:(BOOL)flag
{
	isSelectedIndex = flag;
	[self setNeedsDisplay];
}

- (void)setFrame:(CGRect)f
{
	[super setFrame:f];
	[contentView setFrame:[self bounds]];
}

- (void)setNeedsDisplay
{
	[super setNeedsDisplay];
	[contentView setNeedsDisplay];
}

- (void)drawContentView:(CGRect)r
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	UIColor *bgColor;
	
	if (self.highlighted)
		bgColor = [UIColor clearColor];
	else
		bgColor = self.isEven ? [UIColor colorWithWhite:0.0 alpha:0.25] : [UIColor clearColor];
	
	UIColor *textColor = [UIColor whiteColor];
	UIColor *dividerColor = self.highlighted ? [UIColor clearColor] : [UIColor colorWithRed:0.986 green:0.933 blue:0.994 alpha:0.13];
	
	[bgColor set];
	CGContextFillRect(context, r);
	
	[textColor set];
	
	[title drawInRect:CGRectMake(75, 12, 185, 15) withFont:textFont lineBreakMode:UILineBreakModeTailTruncation];
	[number drawInRect:CGRectMake(5, 12, 35, 15) withFont:textFont lineBreakMode:UILineBreakModeTailTruncation];
	[duration drawInRect:CGRectMake(270, 12, 45, 15) withFont:textFont lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentRight];
	
	[dividerColor set];
	
	CGContextSetLineWidth(context, 0.5);
	
	CGContextMoveToPoint(context, 63.5, 0.0);
	CGContextAddLineToPoint(context, 63.5, r.size.height);
	
	CGContextMoveToPoint(context, 260.5, 0.0);
	CGContextAddLineToPoint(context, 260.5, r.size.height);
	
	CGContextStrokePath(context);
	
	if (self.isSelectedIndex)
	{		
		[self.highlighted ? [UIColor whiteColor] : [UIColor colorWithRed:0.090 green:0.274 blue:0.873 alpha:1.000] set];
		
		CGContextMoveToPoint(context, 45, 17);
		CGContextAddLineToPoint(context, 45, 27);
		CGContextAddLineToPoint(context, 55, 22);
		
		CGContextClosePath(context);
		
		CGContextFillPath(context);
	}
}

@end
