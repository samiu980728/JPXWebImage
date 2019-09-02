//
//  UIImageView+JPXWebImage.h
//  JPXWebImageFANG222
//
//  Created by 萨缪 on 2019/6/10.
//  Copyright © 2019年 萨缪. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JPXWebImageDonloader.h"
#import "JPXWebImageDownloaderOperation.h"
#import "JPXWebImageCache.h"
#import "JPXWebImageManager.h"

@interface UIImageView (JPXWebImage)

- (void)jpx_setImageWithURL:(NSString *)url placeHolderImage:(UIImage *)placeholderImage;


@end
