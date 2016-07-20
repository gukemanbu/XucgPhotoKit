//
//  XucgCropController.m
//  PhotoKitDemo
//
//  Created by xucg on 7/20/16.
//  Copyright © 2016 xucg. All rights reserved.
//  Welcome visiting https://github.com/gukemanbu/XucgPhotoKit

#import "XucgCropController.h"

@interface XucgCropController ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, assign) float imageScale;

@end

@implementation XucgCropController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"照片";
    self.view.backgroundColor = [UIColor blackColor];
    // 这句很重要哦，在有navigation的情况下，去掉后发现scrollView里元素上边距无端的多出了一个导航栏的高度
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    // 右确定
    UIButton *okButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 20)];
    [okButton setTitle:@"确认" forState:UIControlStateNormal];
    [okButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    okButton.titleLabel.font = [UIFont systemFontOfSize:17];
    [okButton addTarget:self action:@selector(okButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:okButton];
    
    CGFloat top = (kScreenHeight - kScreenWidth) / 2;
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, top, kScreenWidth, kScreenWidth)];
    _scrollView.delegate = (id<UIScrollViewDelegate>)self;
    _scrollView.minimumZoomScale = 1.0;
    _scrollView.maximumZoomScale = 5.0;
    _scrollView.layer.borderColor = [UIColor whiteColor].CGColor;
    _scrollView.layer.borderWidth = 1;
    _scrollView.layer.masksToBounds = NO;
    CGFloat contentWidth = kScreenWidth;
    CGFloat contentHeight = kScreenWidth;
    if (_srcImage.size.width > _srcImage.size.height) {
        contentWidth = (_srcImage.size.width * contentHeight) / _srcImage.size.height;
        _imageScale = _srcImage.size.width / contentWidth;
    } else {
        contentHeight = (_srcImage.size.height * contentWidth) / _srcImage.size.width;
        _imageScale = _srcImage.size.height / contentHeight;
    }
    
    _scrollView.contentSize = CGSizeMake(contentWidth, contentHeight);
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.alwaysBounceVertical = YES;
    _scrollView.alwaysBounceHorizontal = YES;
    [self.view addSubview:_scrollView];
    
    _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, contentWidth, contentHeight)];
    _imageView.backgroundColor = [UIColor whiteColor];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.image = _srcImage;
    [_scrollView addSubview:_imageView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void) setSrcImage:(UIImage *)srcImage {
    _srcImage = srcImage;
    _imageView.image = srcImage;
}

-(UIView*) viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _imageView;
}

-(void) scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
}

- (void)okButtonAction:(id)sender {
    float zoomScale = 1.0 / [_scrollView zoomScale];
    
    CGRect rect;
    rect.origin.x = [_scrollView contentOffset].x * zoomScale * _imageScale;
    rect.origin.y = [_scrollView contentOffset].y * zoomScale * _imageScale;
    rect.size.width = [_scrollView bounds].size.width * zoomScale * _imageScale;
    rect.size.height = [_scrollView bounds].size.height * zoomScale * _imageScale;
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([[_imageView image] CGImage], rect);
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    // 发送通知
    NSNotification *notice = [NSNotification notificationWithName:kXucgCropedImage object:newImage userInfo:nil];
    [[NSNotificationCenter defaultCenter]postNotification:notice];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
