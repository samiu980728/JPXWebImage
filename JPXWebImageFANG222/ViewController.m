//
//  ViewController.m
//  JPXWebImageFANG222
//
//  Created by 萨缪 on 2019/6/10.
//  Copyright © 2019年 萨缪. All rights reserved.
//

#import "ViewController.h"
#import "JPXWebImageCache.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSString * urlStr = [NSString stringWithFormat:@"https://raw.githubusercontent.com/onevcat/Kingfisher/master/images/kingfisher-1.jpg"];
    UIImageView * imageView = [[UIImageView alloc] init];
    [imageView jpx_setImageWithURL:urlStr placeHolderImage:nil];
    imageView.frame = CGRectMake(100, 100, 200, 200);
    [self.view addSubview:imageView];
//    JPXWebImageCache * imagecache = [[JPXWebImageCache alloc] init];
//    [imagecache storeImage:imageView.image forKey:@"xxx"];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
