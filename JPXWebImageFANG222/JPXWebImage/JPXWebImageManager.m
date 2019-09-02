//
//  JPXWebImageManager.m
//  JPXWebImageFANG222
//
//  Created by 萨缪 on 2019/6/10.
//  Copyright © 2019年 萨缪. All rights reserved.
//

#import "JPXWebImageManager.h"
#import "JPXWebImageDonloader.h"
#import "JPXWebImageCache.h"

@interface JPXWebImageManager ()

@property (nonatomic, strong) JPXWebImageDonloader * downloader;

@property (nonatomic, strong) JPXWebImageCache * cache;

@end

@implementation JPXWebImageManager

+ (instancetype)sharedManager {
    dispatch_once_t once;
    static id manager;
    dispatch_once(&once, ^{
        manager = [self new];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.downloader = [JPXWebImageDonloader sharedDownloader];
        self.cache = [JPXWebImageCache sharedImageCache];
    }
    return self;
}

- (void)loadImageWithURL:(NSString *)url completedBlock:(JPXWebImageCompletedBlock)completedBlock {
    if (!url) {
        completedBlock(nil, nil, NO);
        return;
    }
    
    //先从内存中取 如果没有再去下载
    //目的是在这里获取 有咩有一个方法可以在
    UIImage * image = [self.cache getImageFromCacheKey:url];
    
    //如果图片不存在 再进行下载
    if (!image) {
#pragma mark 在这个方法的实现中 并没有completedBlock的调用
    [self.downloader downloadImageWithURL:url completedBlock:^(UIImage *image, NSError *error, BOOL isFinished) {
        if (image && !error && isFinished) {
            completedBlock(image, error, isFinished);
        } else {
            completedBlock(image, error, isFinished);
        }
    }];
    } else {
        //如果Image存在 传入即可
        completedBlock(image, nil, YES);
    }
    
    
}

@end
