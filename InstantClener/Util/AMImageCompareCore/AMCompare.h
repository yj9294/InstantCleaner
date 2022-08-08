//
//  AMCompare.h
//  DeDuplicationImage
//
//  Created by mac on 2021/4/20.
//

#import <Foundation/Foundation.h>
@class UIImage;
NS_ASSUME_NONNULL_BEGIN

@interface AMCompare : NSObject
- (void) handleLowLevelImage:(UIImage*) representObjct withImage:(UIImage*) challengeObject;
- (void) handleHighLevelImage:(UIImage*) representObjct withImage:(UIImage*) challengeObject;

- (BOOL) phashCompare;
- (BOOL) orbCompare;
- (BOOL) histogramCompare;
@end

NS_ASSUME_NONNULL_END
