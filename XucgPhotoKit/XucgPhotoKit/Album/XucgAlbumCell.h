//
//  XucgAlbumCell.h
//  PhotoKitDemo
//
//  Created by xucg on 7/18/16.
//  Copyright © 2016 xucg. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XucgAlbumCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView1;
@property (weak, nonatomic) IBOutlet UIImageView *imageView2;
@property (weak, nonatomic) IBOutlet UIImageView *imageView3;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;

- (void)resetCoverImage;

@end
