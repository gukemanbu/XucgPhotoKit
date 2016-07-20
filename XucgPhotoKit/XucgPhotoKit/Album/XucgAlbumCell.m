//
//  XucgAlbumCell.m
//  PhotoKitDemo
//
//  Created by xucg on 7/18/16.
//  Copyright © 2016 xucg. All rights reserved.
//  Welcome visiting https://github.com/gukemanbu/XucgPhotoKit

#import "XucgAlbumCell.h"

@implementation XucgAlbumCell


- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UIColor *coverBgColor = [UIColor colorWithRed:(239.0 / 255.0) green:(239.0 / 255.0) blue:(244.0 / 255.0) alpha:1.0];
    CGFloat borderWidth = 1 / [UIScreen mainScreen].scale;
    _imageView1.backgroundColor = coverBgColor;
    _imageView1.layer.borderColor = [[UIColor whiteColor] CGColor];
    _imageView1.layer.borderWidth = borderWidth;
    
    _imageView2.backgroundColor = coverBgColor;
    _imageView2.layer.borderColor = [[UIColor whiteColor] CGColor];
    _imageView2.layer.borderWidth = borderWidth;
    
    _imageView3.backgroundColor = coverBgColor;
    _imageView3.layer.borderColor = [[UIColor whiteColor] CGColor];
    _imageView3.layer.borderWidth = borderWidth;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)resetCoverImage {
    _imageView1.image = [UIImage imageNamed:@"empty-album"];
    _imageView2.image = [UIImage imageNamed:@"empty-album"];
    _imageView3.image = [UIImage imageNamed:@"empty-album"];
}

@end
