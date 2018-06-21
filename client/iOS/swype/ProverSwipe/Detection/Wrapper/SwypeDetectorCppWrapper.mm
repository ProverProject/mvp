#import "SwypeDetectorCppWrapper.h"
#import <CoreImage/CoreImage.h>
#import <UIKit/UIKit.h>

@interface SwypeDetectorCppWrapper()
@property (nonatomic, assign) SwypeDetect detector;
@property (nonatomic, assign) BOOL isFirstFrame;
@end

@implementation SwypeDetectorCppWrapper

- (instancetype)init {
    self = [super init];
    _isFirstFrame = true;
    return self;
}

-(void)setSwype:(NSString*)swype {
    _detector.setSwype(std::string([swype UTF8String]));
}

-(void)processFrame:(CVImageBufferRef)imageBuffer
          timestamp:(uint)timestamp
              state:(int *)state
              index:(int *)index
                  x:(int *)x
                  y:(int *)y
              debug:(int *)debug {
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    int width = (int)CVPixelBufferGetWidth(imageBuffer);
    int height = (int)CVPixelBufferGetHeight(imageBuffer);
    int bytePerRow = (int)CVPixelBufferGetBytesPerRow(imageBuffer);
    unsigned char *pixels = (unsigned char *) CVPixelBufferGetBaseAddress(imageBuffer);
    
    cv::Mat sourceMat = cv::Mat(height, width,
                                CV_8UC4, pixels,
                                bytePerRow);
    
    // save source image
//      NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//      NSString *sourceFilePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"source_image.png"];
//      cv::imwrite(cv::String([sourceFilePath UTF8String]), sourceMat);
    //------------------
    
    cv::Mat grayMat;
    cv::cvtColor(sourceMat, grayMat, cv::COLOR_BGR2GRAY);
    // save gray image
//    NSString *grayFilePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"gray_image.png"];
//    cv::imwrite(cv::String([grayFilePath UTF8String]), grayMat);
    // ---------------
    
    cv::Mat resizeMat;
    cv::resize(grayMat, resizeMat, cv::Size(), 0.1, 0.1, CV_INTER_LINEAR);
    // save resize image
//    NSString *resizeFilePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"resize_image.png"];
//    cv::imwrite(cv::String([resizeFilePath UTF8String]), resizeMat);
    //------------------
    
    int resizeWidth = resizeMat.cols;
    int resizeHeight = resizeMat.rows;
    
    if (_isFirstFrame) {
        _isFirstFrame = false;
        _detector = SwypeDetect();
        _detector.init(double(resizeWidth) / double(resizeHeight),
                       resizeWidth,
                       resizeHeight);
        _detector.setRelaxed(false);
    }
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    _detector.processMat(resizeMat, timestamp,
                         *state, *index, *x, *y, *debug);
}

@end
