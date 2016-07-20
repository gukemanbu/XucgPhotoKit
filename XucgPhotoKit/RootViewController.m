//
//  RootViewController.m
//  PhotoKitDemo
//
//  Created by xucg on 7/18/16.
//  Copyright © 2016 xucg. All rights reserved.
//

#import "RootViewController.h"
#import "XucgAlbumController.h"

@interface RootViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *selectedImage;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"XucgPhotoKit";

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didSeletedPicture:) name:kXucgCropedImage object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)enterButtonAction:(id)sender {
    XucgAlbumController *albumController = [[XucgAlbumController alloc] init];
    [self.navigationController pushViewController:albumController animated:YES];
}

- (void)didSeletedPicture:(NSNotification*)notification {
    UIImage *newImage = [notification object];
    [_selectedImage setImage:newImage];
}

-(void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
