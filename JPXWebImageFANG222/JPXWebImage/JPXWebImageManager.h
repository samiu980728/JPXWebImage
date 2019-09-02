//
//  JPXWebImageManager.h
//  JPXWebImageFANG222
//
//  Created by 萨缪 on 2019/6/10.
//  Copyright © 2019年 萨缪. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^JPXWebImageCompletedBlock)(UIImage * image, NSError * error, BOOL isFinished);

@interface JPXWebImageManager : NSObject

- (void)loadImageWithURL:(NSString *)url completedBlock:(JPXWebImageCompletedBlock)completedBlock;

+ (instancetype)sharedManager;

@end
