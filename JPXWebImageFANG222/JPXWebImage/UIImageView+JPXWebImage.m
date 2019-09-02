//
//  UIImageView+JPXWebImage.m
//  JPXWebImageFANG222
//
//  Created by 萨缪 on 2019/6/10.
//  Copyright © 2019年 萨缪. All rights reserved.
//

#import "UIImageView+JPXWebImage.h"
#import "JPXWebImageCache.h"
#import "JPXWebImageDonloader.h"


@implementation UIImageView (JPXWebImage)



- (void)jpx_setImageWithURL:(NSString *)url placeHolderImage:(UIImage *)placeholderImage
{
    if (!url) {
        return;
    }
    
    if (placeholderImage) {
        self.image = placeholderImage;
    }
    
    __weak __typeof (self)wself = self;
    //该看manager类这个方法了！！！
    
    __weak __typeof (self) hhelf = wself;
#pragma mark 可不可以在这个方法使用之前先判断一下这个image是否存入磁盘？ 如果已经存入磁盘 那么就直接返回磁盘中的
    JPXWebImageCache * imageCache = [JPXWebImageCache sharedImageCache];
    //对哦 懂了 你判断图片是否已经缓存 不能从self.memCache中取图片啊 你得从系统盘的cache中取
#pragma mark 首要：获取系统磁盘 这个也不能用objectForKey来取了 这就得对比路径 然后看是否存在这个图片文件！
    __block UIImage * cacheImage = [[UIImage alloc] init];
    dispatch_barrier_async(dispatch_get_main_queue(), ^{
        cacheImage = [imageCache fetchimageFromDiskIfWeCanDoItWithKey:url];
    });
    
    if (cacheImage) {
        
        
        
        //OK看来目的已经达到 先看是否缓存 如果缓存了 就不用下载了
        
        //该看 为什么async可以 sync就不行
        
        dispatch_async(dispatch_get_main_queue(), ^{
                UIImageView * imageView = (UIImageView *)hhelf;
                imageView.image = cacheImage;
                [hhelf setNeedsLayout];
            JPXWebImageCache * imageCache = [[JPXWebImageCache alloc] init];
            [imageCache storeImage:cacheImage forKey:url];
        });
    } else {
    
    
    [[JPXWebImageManager sharedManager] loadImageWithURL:url completedBlock:^(UIImage *image, NSError *error, BOOL isFinished) {
        //
        __strong __typeof (wself) sself = wself;
        
#pragma mark 这里为什么要用异步
        //必须得等主线程执行完这个代码块之中的所有程序后 主线程才会继续执行
        
//        if (image && !error && isFinished) {
//            dispatch_sync(dispatch_get_main_queue(), ^{
//                UIImageView * imageView = (UIImageView *)sself;
//                imageView.image = image;
//#pragma mark 这里为什么要用这个方法？  因为需要在获得照片后强制刷新含有UIImageView页面的布局
//                [sself setNeedsLayout];
//            });
//        }
        
        
        
        
#pragma mark  这有个问题 为什么改成asyuc就能运行？ 而变成syn就不能运行
        dispatch_async(dispatch_get_main_queue(), ^{
            if (image && !error && isFinished) {
                UIImageView * imageView = (UIImageView *)sself;
                imageView.image = image;
#pragma mark 这里为什么要用这个方法？  因为需要在获得照片后强制刷新含有UIImageView页面的布局
                [sself setNeedsLayout];
            } else {
//
            }
        });
    }];
    }
}

@end

