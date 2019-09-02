//
//  JPXWebImageCache.m
//  JPXWebImageFANG222
//
//  Created by 萨缪 on 2019/6/10.
//  Copyright © 2019年 萨缪. All rights reserved.
//

#import "JPXWebImageCache.h"
#import <CommonCrypto/CommonDigest.h>

static NSString * const kDefaultDiskPath = @"JPXWebImageDiskCache";

@interface JPXWebImageCache ()

@property (nonatomic, strong) NSFileManager * fileManager;

@property (nonatomic, strong) NSCache * memCache;

@property (nonatomic, strong) dispatch_queue_t ioQueue;

@property (nonatomic, strong) NSString * diskCachePathStr;

@end

@implementation JPXWebImageCache

+ (instancetype)sharedImageCache
{
    dispatch_once_t once;
    static id manager;
    dispatch_once(&once, ^{
        manager = [self new];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        //path初始化
//        iPhone会为每一个应用程序生成一个私有目录，这个目录位于：
//        /Users/sundfsun2009/Library/Application Support/iPhone Simulator/User/Applications下，
//        并随即生成一个数字字母串作为目录名，在每一次应用程序启动时，这个字母数字串都是不同于上一次。
//        所以通常使用Documents目录进行数据持久化的保存，而这个Documents目录可以通过：
//        NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserdomainMask，YES) 得到。
//        如果要指定其他文件目录，比如Caches目录，需要更换目录工厂常量，上面代码其他的可不变：
        
        //这个的思路是放到library下的Caches中
        NSArray * paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        
        NSLog(@"paths = %@",paths);
        
        NSString * path = [paths[0] stringByAppendingPathComponent:kDefaultDiskPath];
        
//        NSLog(@"")
        
        NSString * fullName = [@"com.jpx.JPXWebImageCache" stringByAppendingString:kDefaultDiskPath];
        
        self.ioQueue = dispatch_queue_create("com.jpx.JPXWebImageCache", DISPATCH_QUEUE_CONCURRENT);
        
        self.memCache = [NSCache new];
        
        if (path != nil) {
            //图片存储的最直接地址
            self.diskCachePathStr = [path stringByAppendingPathComponent:fullName];
            NSLog(@"self.diskCachePathStr = %@",self.diskCachePathStr);
        }
        
        self.fileManager = [NSFileManager new];
    }
    return self;
}

#pragma mark 是init 先执行还是 这个storeImage先执行？  因为如果init先执行的话 那怎么在init里面获得目录啊？


//看到这了 在viewController中没有用到这个文件 所以没有下载到电脑中 把图片 任务：  自己把这个类是使用加上去 

#pragma mark  执行的先后顺序 还是执行的先后顺序有问题 
- (void)storeImage:(UIImage *)image forKey:(NSString *)key
{
    //1.需要一个队列存储加载图片数组 2.需要一个NSCache吧图片存入内存 3.需要一个NSFileManager 来创建文件
    //先看内存中有没有包含 然后再链接成一个完整的路径 没有包含就是存入
    if (!image || !key) {
        return;
    }
    [self.memCache setObject:image forKey:key];
    UIImage * testImage = [self.memCache objectForKey:key];
    if (testImage) {
        NSLog(@"yes oh 上帝");
    } else {
        NSLog(@"天哪 我亲爱的洛丽塔");
    }
    dispatch_sync(self.ioQueue, ^{
        //前面那个是创建目录名 这个是真真切切的创建一个目录
        //先把照片转换为NSData 类型
        //然后 首先创建文件目录
        //创建文件目录
        if (![self.fileManager fileExistsAtPath:self.diskCachePathStr]) {
            [self.fileManager createDirectoryAtPath:self.diskCachePathStr withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        //再然后在该文件目录下创建完整的路径
        //然后创建含有该image路径的完整path
#pragma mark  这个imagePath完整路径是在加上照片名称这个后缀之后 叫做完整路径
        NSString * imagePath = [self.diskCachePathStr stringByAppendingPathComponent:[self getImageNameFromCacheKey:key]];
        
        
        //到这了 问题是下载为什么那么慢？？？ 是不是因为在主线程中执行的？？
        ///还有就是 每次下载到的目录地址是随机的！ 很迷惑
       
        NSData * data = UIImagePNGRepresentation(image);
        [self.fileManager createFileAtPath:imagePath contents:data attributes:nil];
    });
}

- (UIImage *)getImageFromCacheKey:(NSString *)key
{
    //通过key找到image 最本质的操作是 NSCache中的objectForKey方法
    if (!key) {
        return nil;
    }
#pragma mark  这不是在这个方法之前已经存入memCache中了么，，， 为啥会找不到呢
    
//    for (id cache in [self.memCache ) {
//        NSLog(@"cache = %@",cache);
//    }
    
    UIImage * image = [self.memCache objectForKey:key];
    if (image) {
        return image;
    }
    //如果image不存在 就有些麻烦了 重新获取一下image的完整路径 再次查找一下
    NSString * imagePath = [self.diskCachePathStr stringByAppendingPathComponent:[self getImageNameFromCacheKey:key]];
    if ([self.fileManager fileExistsAtPath:imagePath]) {
        NSData * data = [NSData dataWithContentsOfFile:imagePath];
        if (data) {
            image = [UIImage imageWithData:data];
            return image;
        }
    }
    return nil;
}

- (NSString *)getImageNameFromCacheKey:(NSString *)key
{
    const char *str = key.UTF8String;
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%@",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10],
                          r[11], r[12], r[13], r[14], r[15], [key.pathExtension isEqualToString:@""] ? @"" : [NSString stringWithFormat:@".%@", key.pathExtension]];
    
    NSLog(@"fileName = %@",filename);
    
    return filename;
}

//判断照片是否存储在磁盘
- (UIImage *)fetchimageFromDiskIfWeCanDoItWithKey:(NSString *)key {
    NSString * imagePath = [self.diskCachePathStr stringByAppendingPathComponent:[self getImageNameFromCacheKey:key]];
    //然后把imagePath转换成image
    UIImage * pathImage = [UIImage imageWithContentsOfFile:imagePath];
//    if ([self.fileManager fileExistsAtPath:self.diskCachePathStr]) {
//
//    }
//    UIImage * image = [self.memCache objectForKey:key];
    if (pathImage) {
        NSLog(@"nice 哈哈哈哈哈哈");
        return pathImage;
    }
    return nil;
}

@end
