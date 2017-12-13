//
//  Monitor.m
//  IOTCamViewer
//
//  Created by tutk on 1/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#define PT_SPEED 8
#define PT_DELAY 1.5

#import "Monitor.h"
#import "Camera2.h"
#import "AVIOCTRLDEFs.h"
#import "FHVideoRecorder.h"

@interface Monitor () <CameraDelegate>
{    
    id<MonitorTouchDelegate>delegate;    
    NSCamera *camera;
       
    CGPoint gestureStartPoint;
    CGPoint initFontSize;    
    NSInteger minGestureLength;
    NSInteger maxVariance;
}

@end

@implementation Monitor

@synthesize delegate;

-(BOOL)dataIsValidJPEG:(NSData *)data
{
    if (!data || data.length < 2) return NO;
    
    NSInteger totalBytes = data.length;
    const char *bytes = (const char*)[data bytes];
    
    return (bytes[0] == (char)0xff &&
            bytes[1] == (char)0xd8 &&
            bytes[totalBytes-2] == (char)0xff &&
            bytes[totalBytes-1] == (char)0xd9);
}

- (void)dealloc
{
    self.delegate = nil;    
    [super dealloc];
}

- (UIImage *) getUIImage:(char *)buff Width:(NSInteger)width Height:(NSInteger)height 
{
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buff, width * height * 3, NULL);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef imgRef = CGImageCreate(width, height, 8, 24, width * 3, colorSpace, kCGBitmapByteOrderDefault, provider, NULL, true,  kCGRenderingIntentDefault);
        
    UIImage *img = [UIImage imageWithCGImage:imgRef];
    
    
    if (imgRef != nil) {
        CGImageRelease(imgRef);
        imgRef = nil;
    }   
    
    if (colorSpace != nil) {
        CGColorSpaceRelease(colorSpace);
        colorSpace = nil;
    }
    
    if (provider != nil) {
        CGDataProviderRelease(provider);
        provider = nil;
    } 
    
    return img;
}

#pragma mark - Public Methods

- (void)attachCamera:(NSCamera *)cam
{    
    camera = cam;
    camera.delegateForMonitor = self;
}

- (void)deattachCamera 
{      
    camera.delegateForMonitor = nil;
    camera = nil;
}

- (void)setMinimumGestureLength:(NSInteger)length MaximumVariance:(NSInteger)variance 
{    
    minGestureLength = length;
    maxVariance = variance;
    
    UIPinchGestureRecognizer *pinch = [[[UIPinchGestureRecognizer alloc]
                                        initWithTarget:self    
                                        action:@selector(doPinch:)] autorelease];   
    [self addGestureRecognizer:pinch];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event 
{    
    UITouch *touch = [touches anyObject];
    gestureStartPoint = [touch locationInView:self];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{ 
    UITouch *touch = [touches anyObject];
    CGPoint currentPosition = [touch locationInView:self];
    
    CGFloat deltaX = currentPosition.x - gestureStartPoint.x;
    CGFloat deltaY = currentPosition.y - gestureStartPoint.y;
    Direction direction = DirectionNone;
    
    // pan
    if (fabsf(deltaX) >= minGestureLength && fabsf(deltaY) <= maxVariance) {
        
        if (deltaX > 0) direction = DirectionPanLeft;
        else direction = DirectionPanRight;
    }
    // tilt
    else if (fabsf(deltaY) >= minGestureLength && fabsf(deltaX) <= maxVariance) {
        
        if (deltaY > 0) direction = DirectionTiltUp;
        else direction = DirectionTiltDown;
    } 
    
    if (direction != DirectionNone) {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(monitor:gestureSwiped:)]) {
            [self.delegate monitor:self gestureSwiped:direction];
        }
        else {
            
            unsigned char ctrl = -1;
            if (direction == DirectionTiltUp) ctrl = AVIOCTRL_PTZ_UP;
            else if (direction == DirectionTiltDown) ctrl = AVIOCTRL_PTZ_DOWN;
            else if (direction == DirectionPanLeft) ctrl = AVIOCTRL_PTZ_LEFT;
            else if (direction == DirectionPanRight) ctrl = AVIOCTRL_PTZ_RIGHT;    
            
            [camera PTZ:ctrl];
        }
    }
}

- (void)doPinch:(UIPinchGestureRecognizer *)pinch 
{     
    if (pinch.state == UIGestureRecognizerStateEnded) {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(monitor:gesturePinched:)]) {
            [self.delegate monitor:self gesturePinched:pinch.scale];
        }
    }
}

- (void)receiveFrameData:(NSNotification *)notification 
{
    //dispatch_async(dispatch_get_main_queue(), ^{
            
        NSDictionary *dict = [notification userInfo];    
        NSString *name = [notification name];
        
        if ([name isEqualToString:@"didReceiveRawDataFrame"]) {
         
            NSData *data = (NSData *)[dict valueForKey:@"rawData"];
            NSNumber *width = (NSNumber *)[dict valueForKey:@"videoWidth"];
            NSNumber *height = (NSNumber *)[dict valueForKey:@"videoHeight"];
               
            CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, [data bytes], [width intValue] * [height intValue] * 3, NULL);
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGImageRef imgRef = CGImageCreate([width intValue], [height intValue], 8, 24, [width intValue] * 3, colorSpace, kCGBitmapByteOrderDefault, provider, NULL, true,  kCGRenderingIntentDefault);
            
            UIImage *img = [UIImage imageWithCGImage:imgRef];
            self.image = [img retain];
            
            if (imgRef != nil) {
                CGImageRelease(imgRef);
                imgRef = nil;
            }   
            
            if (colorSpace != nil) {
                CGColorSpaceRelease(colorSpace);
                colorSpace = nil;
            }
            
            if (provider != nil) {
                CGDataProviderRelease(provider);
                provider = nil;
            } 
            
            [data release];
            [width release];
            [height release];
            [dict release];

            NSLog(@"recv frame data with w:%d, h:%d", [width intValue], [height intValue]);
        }
        else if ([name isEqualToString:@"didReceiveJPEGDataFrame"]) {
            
            NSData *data = (NSData *)[dict valueForKey:@"jpegData"];
            self.image = [UIImage imageWithData:data];        
        }   
    //});
}

#pragma mark - CameraDelegate Methods
- (void)camera:(NSCamera *)camera didReceiveJPEG:(UIImage *)image{
    [[FHVideoRecorder getInstance] writeVideoWithUIImage:[image CGImage]];
    self.image = image;
}

- (void)camera:(Camera *)camera didReceiveRawDataFrame:( NSData *)imgData VideoWidth:(NSInteger)width VideoHeight:(NSInteger)height
{
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    //CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, (const unsigned char *) [imgData bytes], width * height * 3,kCFAllocatorNull);
    CFDataRef data = CFDataCreate(kCFAllocatorDefault, (const unsigned char *) [imgData bytes], width * height * 3);
 
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef imgRef = CGImageCreate(width, height, 8, 24, width * 3, colorSpace, bitmapInfo, provider, NULL, YES, kCGRenderingIntentDefault);
    
    
    [[FHVideoRecorder getInstance] writeVideoWithUIImage:imgRef];
    self.image = [UIImage imageWithCGImage:imgRef];
    
    CGImageRelease(imgRef);
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
    CFRelease(data);
}

- (void)camera:(Camera *)camera didReceiveJPEGDataFrame2:(NSData *)imgData
{
    if ([self dataIsValidJPEG:imgData]){
        
        self.image = [UIImage imageWithData:imgData];
        [[FHVideoRecorder getInstance] writeVideoWithUIImage:[self.image CGImage]];
    }
    else {
        NSLog(@"JPEG data broken - Monitor.m");
    }
}
@end
