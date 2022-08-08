//
//  AMSimilarityManager.h
//  DeDuplicationImage
//
//  Created by mac on 2021/4/13.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class PHAsset;
@interface AMSimilarityManager : NSObject
/// 输入为以天为单位的(PHAsset)数组
+ (NSDictionary*)similarityGroup:(NSArray<PHAsset*>*) array;

+ (NSDictionary*)similarityVideoGroup:(NSArray<PHAsset*>*) array;

+ (void)startClean;

+ (void)stopClean;
@end

NS_ASSUME_NONNULL_END
