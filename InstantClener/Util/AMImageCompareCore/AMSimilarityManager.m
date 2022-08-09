//
//  AMSimilarityManager.m
//  DeDuplicationImage
//
//  Created by mac on 2021/4/13.
//

#import "AMSimilarityManager.h"
#import "AMPhashAssetsCompare.h"
#import "AMHistogramCompare.h"
#import "AMOrbAssetsCompare.h"
#import "AMCompare.h"
#import "ImageCompare.h"
#import <Photos/Photos.h>
#import "InstantClener-Swift.h"

#define MaxTimeGap 3600*3  //三小时最大分组间隔
#define MaxHamming 10
#define MaxHis 0.6
#define MaxOrb 0.15
#define ORBCompareSize CGSizeMake(224,224)
#define HSVCompareSize CGSizeMake(224,224)
#define PHASHCompareSize CGSizeMake(120,120)

BOOL stopClean = FALSE;

@implementation AMSimilarityManager
//以一小时为单位分离数组
+ (NSDictionary*)similarityGroup:(NSArray<PHAsset*>*) array{
    NSMutableArray* inputArray = [NSMutableArray arrayWithArray:array];
    // 相似
    NSMutableArray* outputArray = [NSMutableArray array];
    // 屏幕截图
    NSMutableArray *screenshotArray = [NSMutableArray array];
    // 大图片
    NSMutableArray *bigImageArray = [NSMutableArray array];
    // 模糊图片
    NSMutableArray *blurryArray = [NSMutableArray array];
    
    int i = 0;
    int j = 0;
    
    //理论上会根据输入数组的个数，创建相应的分类数组
    while(i < inputArray.count) {
        if (stopClean) {
            return @{@"similar": @[], @"screenshot": @[], @"bigImage": @[], @"blurry": @[]};
        }
        //取出代表元素
        //添加自动释放池，处理临时变量
        @autoreleasepool {
            
            PHAsset* representObjct = inputArray[i];
            UIImage* repImage =  [AMSimilarityManager syncRequestImage:representObjct targetSize:PHASHCompareSize];
            NSData *data = [AMSimilarityManager syncRequestImageData:representObjct];
            PhotoItem *model = [[PhotoItem alloc] initWithAsset:representObjct image:repImage imageDataLength:data.length isSelected:false isBest:false second:0];
            
            //初始化一个离群数组，并且放入代表元素
            NSMutableArray* disGroupArray = [NSMutableArray arrayWithObject:model];

            /// 截屏图片
            if (representObjct.mediaSubtypes == PHAssetMediaSubtypePhotoScreenshot) {
                [screenshotArray addObject:model];
            }
            
            /// 大图
            if (data.length > 1024.0 * 1024.0 * 3.0) {
                [bigImageArray addObject:model];
            }
            
            /// 模糊图片
            if ([self wheatherTheImageBlurry:repImage] == YES) {
                [blurryArray addObject:model];
            }
            
            j = i + 1;
            while (j < inputArray.count) {
                if (stopClean) {
                    return @{@"similar": @[], @"screenshot": @[], @"bigImage": @[], @"blurry": @[]};
                }
                //添加自动释放池，处理临时变量
                @autoreleasepool {
                    //获取对比对象
                    PHAsset* challengeObject = inputArray[j];
                    UIImage* chaImage = [AMSimilarityManager syncRequestImage:challengeObject targetSize:PHASHCompareSize];
                    NSData *data2 = [AMSimilarityManager syncRequestImageData:challengeObject];

                    PhotoItem *model2 = [[PhotoItem alloc] initWithAsset:challengeObject image:chaImage imageDataLength:data2.length isSelected:false isBest:false second:0];
                    
                    //判断时间是否间隔小于一定的时间间隔
                    if ([self judgeTime:representObjct and:challengeObject]) {
                        //判断相似度
                        if (repImage != nil && chaImage != nil) {
                            if ([self judge:repImage and:chaImage]) {
                                [disGroupArray addObject:model2];
                            }
                        }
                        //继续，指向下一位
                        j++;
                    }
                    else {
                        //因为是升序的如果当前不等，则以后的都不等
                        break;
                    }
                }
            }
            
            if (disGroupArray.count > 1) {
                
                for (PhotoItem* model in disGroupArray) {
                    //从输入数组中，移除已经放入相似集合的数组
                    [inputArray removeObject:model.asset];
                }
                
                [outputArray addObject:disGroupArray];
            }
            else {
                i++;
            }
        }
    }
    return @{@"similar": outputArray, @"screenshot": screenshotArray, @"bigImage": bigImageArray, @"blurry": blurryArray};
}

+ (NSDictionary*)similarityVideoGroup:(NSArray<PHAsset*>*) array{
    NSMutableArray* inputArray = [NSMutableArray arrayWithArray:array];
    // 相似
    NSMutableArray* outputArray = [NSMutableArray array];
    // 大图片
    NSMutableArray *bigVideoArray = [NSMutableArray array];
    
    int i = 0;
    int j = 0;
    
    //理论上会根据输入数组的个数，创建相应的分类数组
    while(i < inputArray.count) {
        if (stopClean) {
            return @{@"similar": @[], @"screenshot": @[], @"bigImage": @[], @"blurry": @[]};
        }
        //取出代表元素
        //添加自动释放池，处理临时变量
        @autoreleasepool {
            
            PHAsset* representObjct = inputArray[i];
            UIImage* repImage =  [AMSimilarityManager syncRequestImage:representObjct targetSize:PHASHCompareSize];
            NSDictionary *resultOfVideo = [AMSimilarityManager requestVideoSize:representObjct];
            PhotoItem *model = [[PhotoItem alloc] initWithAsset:representObjct image:repImage imageDataLength:[resultOfVideo[@"fileSize"] integerValue] isSelected:false isBest:false second:[resultOfVideo[@"duration"] integerValue]];

            
            //初始化一个离群数组，并且放入代表元素
            NSMutableArray* disGroupArray = [NSMutableArray arrayWithObject:model];
            
            /// 大图
            if (model.imageDataLength > 1024.0 * 1024.0 * 30) {
                [bigVideoArray addObject:model];
            }
            
            j = i + 1;
            while (j < inputArray.count) {
                if (stopClean) {
                    return @{@"similar": @[], @"screenshot": @[], @"bigImage": @[], @"blurry": @[]};
                }
                //添加自动释放池，处理临时变量
                @autoreleasepool {
                    
                    //获取对比对象
                    PHAsset* challengeObject = inputArray[j];
                    UIImage* chaImage = [AMSimilarityManager syncRequestImage:challengeObject targetSize:PHASHCompareSize];
                    NSDictionary *resultOfVideo = [AMSimilarityManager requestVideoSize:challengeObject];

                    PhotoItem *model2 = [[PhotoItem alloc] initWithAsset:challengeObject image:chaImage imageDataLength:[resultOfVideo[@"fileSize"] integerValue] isSelected:false isBest:false second:[resultOfVideo[@"duration"] integerValue]];


                    //判断时间是否间隔小于一定的时间间隔
                    if ([self judgeTime:representObjct and:challengeObject]) {
                        //判断相似度
                        if (repImage != nil && chaImage != nil) {
                            if ([self judge:repImage and:chaImage]) {
                                [disGroupArray addObject:model2];
                            }
                        }
                        //继续，指向下一位
                        j++;
                    }
                    else {
                        //因为是升序的如果当前不等，则以后的都不等
                        break;
                    }
                }
            }
            
            if (disGroupArray.count > 1) {
                
                for (PhotoItem* model in disGroupArray) {
                    //从输入数组中，移除已经放入相似集合的数组
                    [inputArray removeObject:model.asset];
                }
                
                [outputArray addObject:disGroupArray];
            }
            else {
                i++;
            }
        }
    }
    return @{@"similar": outputArray, @"bigImage": bigVideoArray};
}

///通过视频URL或者filePath 获取第一帧图片
+ (UIImage *)getVideoThumbnail:(NSURL *)filePath {
    AVAsset *asset = [AVAsset assetWithURL:filePath];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMake(0, 1);
    NSError *error;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:&error];
    UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);  // CGImageRef won't be released by ARC
    return thumbnail;
}

//相似度判断
+ (BOOL)judge:(UIImage*) representObjct and:(UIImage*) challengeObject {
    
    //初始化对比器
    AMCompare* compare = [[AMCompare alloc] init];
    [compare handleLowLevelImage:representObjct withImage:challengeObject];
    
    //感知哈希计算图片轮廓
    if ([compare phashCompare]) {
        //HSV灰度直方图判断图片色差orbCompare
        [compare handleHighLevelImage:representObjct withImage:challengeObject];
        if ([compare histogramCompare]) {
            //ORB匹配
            if ([compare orbCompare]) {
                return YES;
            } else {
                return NO;
            }
        } else {
            return NO;
        }
        
    } else {
        return NO;
    }
}

+ (BOOL)judgeTime:(PHAsset*) representObjct and:(PHAsset*) challengeObject{
    return [representObjct.creationDate timeIntervalSince1970] - [challengeObject.creationDate timeIntervalSince1970] <= MaxTimeGap ? YES : NO;
}


//图像过滤算法
+ (BOOL)phashCompare:(UIImage*) representObjct and:(UIImage*) challengeObject {
    //小于一小时则开始匹配图片相似度
    AMPhashAssetsCompare* compare = [[AMPhashAssetsCompare alloc] init];
    //计算汉明距离
    int distance = [compare handleImage:representObjct withImage:challengeObject];
    
    if (distance < MaxHamming) {
        return YES;
    }
    else {
        return NO;
    }
}

+ (BOOL)histogramCompare:(UIImage*) representObjct and:(UIImage*) challengeObject {
    //进行直方图HSV判断
    AMHistogramCompare* compare = [[AMHistogramCompare alloc] init];
    double mean = [compare handleImage:representObjct withImage:challengeObject];
    
    if (mean >= MaxHis) {
        return YES;
    }
    else {
        
        return NO;
    }
}

+ (BOOL)orbCompare:(UIImage*) representObjct and:(UIImage*) challengeObject {
    AMOrbAssetsCompare* compare = [[AMOrbAssetsCompare alloc] init];
    double similary = [compare handleImage:representObjct withImage:challengeObject];
    
    if (similary >= MaxOrb) {
        return YES;
    }
    else {
        return NO;
    }
}

/// 模糊判断
+ (BOOL)wheatherTheImageBlurry:(UIImage*) representObjct {
    return [ImageCompare wheatherTheImageBlurry:representObjct];
}

+ (UIImage*)syncRequestImage:(PHAsset*) asset targetSize:(CGSize) size {
    __block UIImage* repImage = nil;
    
    PHImageRequestOptions *options = PHImageRequestOptions.new;
    options.synchronous = YES;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        repImage = [[UIImage alloc] initWithData: UIImageJPEGRepresentation(result, 1)];
    }];
    return repImage;
}

+ (NSData*)syncRequestImageData:(PHAsset*) asset {
    __block NSData* repdata = nil;
    
    PHImageRequestOptions *options = PHImageRequestOptions.new;
    options.synchronous = YES;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    
    [[PHImageManager defaultManager] requestImageDataAndOrientationForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, CGImagePropertyOrientation orientation, NSDictionary * _Nullable info) {
        repdata = imageData;
    }];
    
    return repdata;
}

+ (NSDictionary *)requestVideoSize:(PHAsset*) asset {
    __block NSInteger fileAllSize = 0;
    __block NSInteger duration = 0;
    PHVideoRequestOptions *options = PHVideoRequestOptions.new;
    options.version = PHVideoRequestOptionsVersionOriginal;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        AVURLAsset *avAsset = (AVURLAsset *)asset;
        NSArray *keys = @[NSURLTotalFileSizeKey, NSURLFileSizeKey];
        NSError *err = nil;
        NSDictionary *result = [avAsset.URL resourceValuesForKeys:keys error:&err];
        if (err != nil) {
            NSLog(@"[clean] err: %@", err);
        }
        fileAllSize = [[result objectForKey:NSURLTotalFileSizeKey] integerValue];
        CMTime time = avAsset.duration;
        duration = CMTimeGetSeconds(time);
        
        dispatch_semaphore_signal(sem);
    }];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return @{@"fileSize" : @(fileAllSize), @"duration": @(duration)};
}

+ (void)stopClean {
    stopClean = YES;
}

+ (void)startClean {
    stopClean = NO;
}

@end
