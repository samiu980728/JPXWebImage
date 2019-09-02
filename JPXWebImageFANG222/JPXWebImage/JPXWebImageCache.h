//
//  JPXWebImageCache.h
//  JPXWebImageFANG222
//
//  Created by 萨缪 on 2019/6/10.
//  Copyright © 2019年 萨缪. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface JPXWebImageCache : NSObject

- (void)cacheImageForKey:(NSString *)key;

- (UIImage *)getImageFromCacheKey:(NSString *)key;

- (NSString *)getImageNameFromCacheKey:(NSString *)key;

- (void)storeImage:(UIImage *)image forKey:(NSString *)key;

+ (instancetype)sharedImageCache;

- (UIImage *)fetchimageFromDiskIfWeCanDoItWithKey:(NSString *)key;

@end
