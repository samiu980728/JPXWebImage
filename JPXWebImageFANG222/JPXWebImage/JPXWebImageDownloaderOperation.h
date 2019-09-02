//
//  JPXWebImageDownloaderOperation.h
//  JPXWebImageFANG222
//
//  Created by 萨缪 on 2019/6/10.
//  Copyright © 2019年 萨缪. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JPXWebImageDonloader.h"

@interface JPXWebImageDownloaderOperation : NSOperation

@property (nonatomic, strong) NSURLRequest * request;

@property (nonatomic, strong) NSURLSessionTask * sessionDataTask;

- (instancetype)initWithRequest:(NSURLRequest *)request;

- (BOOL)cancel:(id)token;

- (void)start;

- (void)addCompletionBlock:(JPXWebImageDownloadCompletedBlock)completionBlock;

@end
