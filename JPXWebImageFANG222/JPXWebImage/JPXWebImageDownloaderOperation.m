//
//  JPXWebImageDownloaderOperation.m
//  JPXWebImageFANG222
//
//  Created by 萨缪 on 2019/6/10.
//  Copyright © 2019年 萨缪. All rights reserved.
//

#import "JPXWebImageDownloaderOperation.h"

static NSString * const kCompletedBlock = @"kCompletedBlock";

@interface JPXWebImageDownloaderOperation () <NSURLSessionDataDelegate,NSURLSessionTaskDelegate>

@property (nonatomic, assign) BOOL isFinished;

@property (nonatomic, strong) NSURLSessionDataTask * dataDask;

@property (nonatomic, assign) BOOL isExcuting;

@property (nonatomic, strong) NSMutableArray * callBackBlocksArray;

@property (nonatomic, strong) dispatch_queue_t barrierQueue;

@property (nonatomic, strong) NSMutableData * imageData;

@property (nonatomic, strong) NSURLSession * unownedSession;

@property (nonatomic, strong) NSURLSession * ownedSession;

@end

@implementation JPXWebImageDownloaderOperation

- (instancetype)initWithRequest:(NSURLRequest *)request
{
    self = [super init];
    if (self) {
        self.request = [request copy];
        self.isExcuting = NO;
        self.callBackBlocksArray = [[NSMutableArray alloc] init];
        self.barrierQueue = dispatch_queue_create("com.jpx.JPXWebImageDownloaderBarrierQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (void)cancel
{
    @synchronized(self) {
        if (self.isFinished == YES) {
            return;
        }
        //直接调用父类的cancel方法
        [super cancel];
        if (self.dataDask) {
            [self.dataDask cancel];
            if (self.isExcuting == YES) {
                self.isExcuting = NO;
            }
            if (!self.isExcuting) {
                self.isExcuting = YES;
            }
        }
        [self reset];
    }
}

//完成之后
- (void)done {
    self.isExcuting = NO;
    self.isFinished = YES;
    [self reset];
}

//重置
- (void)reset {
    dispatch_barrier_sync(self.barrierQueue, ^{
        [self.callBackBlocksArray removeAllObjects];
    });
    self.imageData = nil;
    self.dataDask = nil;
    if (self.ownedSession) {
        //先取消未完成的任务 再赋值为空
        [self.ownedSession invalidateAndCancel];
        self.ownedSession = nil;
    }
    
}

- (void)addCompletionBlock:(JPXWebImageDownloadCompletedBlock)completionBlock
{
    NSMutableDictionary * dict = [NSMutableDictionary new];
    if (completionBlock) {
        [dict setObject:completionBlock forKey:kCompletedBlock];
    }
    dispatch_barrier_async(self.barrierQueue, ^{
        [self.callBackBlocksArray addObject:dict];
    });
    
}

//找到那个存储completedBlock的数组
- (NSArray *)callBackForKey:(NSString *)key {
    __block NSMutableArray * mutArray = [[NSMutableArray alloc] init];
    mutArray = [self.callBackBlocksArray valueForKey:key];
    return [mutArray copy];
}

- (void)callCompletionBlockWithImage:(UIImage *)image imageData:(NSData *)imageData error:(NSError *)error finished:(BOOL)isFinished {
    NSArray * compltetiosBlocksArray = [self callBackForKey:kCompletedBlock];
    for (JPXWebImageDownloadCompletedBlock completedBlock in compltetiosBlocksArray) {
        completedBlock(image, error, isFinished);
    }
}

#pragma mark 为什么这个方法没有被使用？ 因为start是一个会自动调用的方法
- (void)start {
    //开始要加并发锁的
#pragma mark 什么时候加并发锁 加并发锁的时机
    @synchronized (self) {
    if (self.isCancelled) {
        self.isFinished = YES;
        [self reset];
        return;
    }
    
#pragma mark 不懂为什么要这一句 没有用啊
    NSURLSession * session = self.unownedSession;
    if (!session) {
        NSURLSessionConfiguration * confighration = [NSURLSessionConfiguration defaultSessionConfiguration];
        confighration.timeoutIntervalForRequest = 15;
        /**
         * 2. 创建NSURLSession的对象.
         * 参数一 : NSURLSessionConfiguration类的对象.(第1步创建的对象.)
         * 参数二 : session的代理人. 如果为nil, 系统将会提供一个代理人.
         * 参数三 : 一个队列, 代理方法在这个队列中执行. 如果为nil, 系统会自动创建一系列的队列.
         * 注: 只能通过这个方法给session设置代理人, 因为在NSURLSession中delegate属性是只读的.
         */
        self.ownedSession = [NSURLSession sessionWithConfiguration:confighration delegate:self delegateQueue:nil];
        session = self.ownedSession;
    }
        /** 5. 创建数据类型的任务. */
    self.dataDask = [session dataTaskWithRequest:self.request];
    self.isExcuting = YES;
    }
#pragma mark resume的使用方法  为什么在这里直接就可以用resume? 因为已经创建任务了啊 就剩下执行了
    [self.dataDask resume];
    if (!self.dataDask) {
        NSLog(@"Connection can't be initialized:");
    }
}

#pragma mark NSURLSessionTaskDelegate
#pragma mark 想问这些NSURLSession的代理都会在什么时机被调用？？？
/**  告诉delegate已经接受到服务器的初始应答, 准备接下来的数据任务的操作. */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    //下面这就是SDWebImage中源码的判断请求成功的处理和失败的处理
    if (![response respondsToSelector:@selector(statusCode)] || (((NSHTTPURLResponse *)response).statusCode < 400 && ((NSHTTPURLResponse *)response).statusCode != 304)) {
        
        //限定图片文件的字节长度 防止超过最大长度
        NSInteger expected = response.expectedContentLength > 0 ? (NSInteger)response.expectedContentLength : 0;
        self.imageData = [[NSMutableData alloc] initWithCapacity:expected];
    }
    
    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
}

/** 告诉delegate已经接收到部分数据. */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    //这个不管data是不是空都要加上？？？
    [self.imageData appendData:data];
}

#pragma mark NSURLSessionTaskDelegate
/** 告诉delegate, task已经完成. */
//错误情况 如果没有另当别论
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        NSLog(@"dataTask Error:%@",error.description);
    } else {
#pragma mark  为什么要在这里调用？
        //如果没有错误 调用完成block
        //如果请求的数量大于0 执行completeBlock
        if ([self callBackForKey:kCompletedBlock].count > 0) {
            if (self.imageData) {
                UIImage * image = [UIImage imageWithData:self.imageData];
                
                if (CGSizeEqualToSize(image.size, CGSizeZero)) {
                    
                } else {
                    [self callCompletionBlockWithImage:image imageData:self.imageData error:nil finished:YES];
                }
            }
        }
    }
#pragma mark 这里为什么要用done?
    [self done];
}

//cancel的本质是NSURLDataTask的封装好的cancel方法
- (BOOL)cancel:(id)token
{
    __block BOOL shouldCancel = NO;
    dispatch_barrier_sync(self.barrierQueue, ^{
        //移除该地址上的元素
        [self.callBackBlocksArray removeObjectIdenticalTo:token];
        //如果数目为0 ??
        if (self.callBackBlocksArray.count == 0) {
            shouldCancel = YES;
        }
    });
    if (shouldCancel) {
        [self cancel];
    }
    return shouldCancel;
}

@end
