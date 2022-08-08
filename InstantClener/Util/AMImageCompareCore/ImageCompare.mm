//
//  ImageCompare.m
//

#import "ImageCompare.h"
#import "opencv2/imgproc.hpp"
#import "opencv2/imgproc/types_c.h"
#import <iostream>

@implementation ImageCompare

#pragma mark - 判断图片模糊

// 方差参考值(判断模糊用)
const double delta = 75;
// 判断是否模糊
+ (BOOL)wheatherTheImageBlurry:(UIImage *)image {
    
    unsigned char *data;
    int height, width, step;
    
    int Iij;
    
    double Iave = 0, Idelta = 0;
    
    cv::Mat mat = [ImageCompare cvMatFromUIImage: image];
    
    if (!mat.empty()) {
        cv::Mat gray;
        cv::Mat outGray;
        // 将图像转换为灰度显示
        cv::cvtColor(mat, gray, CV_RGB2GRAY);
        
        cv::Laplacian(gray, outGray, gray.depth());
        
//        cv::convertScaleAbs( outGray, outGray );
        
        IplImage ipl_image = cvIplImage(outGray);
        
        data   = (uchar*)ipl_image.imageData;
        height = ipl_image.height;
        width  = ipl_image.width;
        step   = ipl_image.widthStep;
        
        for(int i=0; i<height; i++)
        {
            for(int j=0; j<width; j++)
            {
                Iij    = (int) data
                [i*width+j];
                Idelta = Idelta + (Iij-Iave)*(Iij-Iave);
            }
        }
        Idelta = Idelta/(width*height);
        
//        std::cout<<"矩阵方差为："<<Idelta<<std::endl;
    }
    
    return (Idelta > delta) ? NO : YES;
}

// UIImage转化成Mat
+ (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

// Mat转化成UIImage
+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {//可以根据这个决定使用哪种
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}


@end
