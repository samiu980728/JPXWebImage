//
//  JPXWebImageDonloader.h
//  JPXWebImageFANG222
//
//  Created by 萨缪 on 2019/6/10.
//  Copyright © 2019年 萨缪. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^JPXWebImageDownloadCompletedBlock)(UIImage * image, NSError * error, BOOL isFinished);

@interface JPXWebImageDonloader : NSObject

@property (nonatomic, readonly) NSUInteger currentDowmloadCount;

+ (instancetype)sharedDownloader;

- (void)downloadImageWithURL:(NSString *)url completedBlock:(JPXWebImageDownloadCompletedBlock)completedBlock;

@end
