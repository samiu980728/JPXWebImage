//
//  JPXWebImageDonloader.m
//  JPXWebImageFANG222
//
//  Created by 萨缪 on 2019/6/10.
//  Copyright © 2019年 萨缪. All rights reserved.
//

#import "JPXWebImageDonloader.h"
#import "JPXWebImageDownloaderOperation.h"

@interface JPXWebImageDonloader ()

@property (nonatomic, strong) NSOperationQueue * downloadQueue;

@property (nonatomic, strong) NSOperation * lastOperation;

@property (nonatomic, strong) NSMutableDictionary * urlOperations;

@property (nonatomic, strong) dispatch_queue_t barrierQueue;

@end

@implementation JPXWebImageDonloader

+ (instancetype)sharedDownloader
{
    static dispatch_once_t once;
    static id downloader;
    dispatch_once(&once, ^{
        downloader = [self new];
    });
    return downloader;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _barrierQueue = dispatch_queue_create("com.jpx.JPXWebImageDownloaderBarrierQueue", DISPATCH_QUEUE_CONCURRENT);
        _downloadQueue = [[NSOperationQueue alloc] init];
        _downloadQueue.name = @"com.jpx.JPXWebImageDownloader";
        _urlOperations = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark 这个completedBlock的最终作用是在 JPXWebImageDownloaderOperation类中的方法 addCompletionBlock:(JPXWebImageDownloadCompletedBlock)completionBlock中把该completeBlock加入一个新建的字典中 并赋值key 然后再把这个图片操作形成的字典添加进一个动态数组中
//看到这了
- (void)downloadImageWithURL:(NSString *)url completedBlock:(JPXWebImageDownloadCompletedBlock)completedBlock
{
    if (!url) {
        if (completedBlock) {
            completedBlock(nil, nil, YES);
        }
        return;
    }
    
    //创建一个块
#pragma mark 创建block的方式
    JPXWebImageDownloaderOperation *(^createDownloaderOperation)(void) = ^() {
        NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15.0];
        //允许不必再次等到Request就可以再次请求
        request.HTTPShouldUsePipelining = YES;
        
        JPXWebImageDownloaderOperation * operation = [[JPXWebImageDownloaderOperation alloc] initWithRequest:request];
        
        operation.queuePriority = NSURLSessionTaskPriorityHigh;
        
        [self.downloadQueue addOperation:operation];
        //添加依赖的作用就是让operation在self.lastOperation后面执行
        [self.lastOperation addDependency:operation];
#pragma mark 这里为什么还要再次赋值一次？
        self.lastOperation = operation;
        return operation;
    };
    
    //上面的块用到这里 completedBlock是用在这里用来传参的
    [self addCompletedBlock:completedBlock forURL:url createCallBack:createDownloaderOperation];
}

//看到这里了 不要再跟着这个看了！！！看源码
- (void)addCompletedBlock:(JPXWebImageDownloadCompletedBlock)completeBlock forURL:(NSString *)urlStr createCallBack:(JPXWebImageDownloaderOperation *(^)(void))createCallBack {
#pragma mark dispatch_barrier_sync 与 dispatch_barrier_async 的区别
///dispatch_barrier_sync将自己的任务插入到队列的时候，需要等待自己的任务结束之后才会继续插入被写在它后面的任务，然后执行它们。
///dispatch_barrier_async将自己的任务插入到队列之后，不会等待自己的任务结束，它会继续把后面的任务插入到队列，然后等待自己的任务结束后才执行后面任务。
    dispatch_barrier_sync(self.barrierQueue, ^{
        //每个urlstr对应一个operation
        JPXWebImageDownloaderOperation * operation = self.urlOperations[urlStr];
        if (!operation) {
            operation = createCallBack();
            __weak JPXWebImageDownloaderOperation * woperation = operation;
            operation.completionBlock = ^{
                JPXWebImageDownloaderOperation * soperation = woperation;
                if (!soperation) {
                    return ;
                }
                if (self.urlOperations[urlStr] == soperation) {
                    [self.urlOperations removeObjectForKey:urlStr];
                }
            };
#pragma mark 注意这个方法不是 addCompletedBlock:(JPXWebImageDownloadCompletedBlock)completeBlock forURL:(NSString *)urlStr createCallBack 方法 把completeBlock和对应的key装入恒存在的对象 self.callBackBlocksArray 中
            [operation addCompletionBlock:completeBlock];
        }
    });
}

- (void)cancel:(NSString *)url {
    dispatch_barrier_sync(self.barrierQueue, ^{
        JPXWebImageDownloaderOperation * operation = self.urlOperations[url];
        BOOL cancel = [operation cancel:url];
        if (cancel) {
            [self.urlOperations removeObjectForKey:url];
        }
    });
}

//懒加载
- (NSUInteger)currentDowmloadCount
{
    return self.downloadQueue.operationCount;
}



@end
