//
//  XucgPhotosController.m
//  PhotoKitDemo
//
//  Created by xucg on 7/19/16.
//  Copyright © 2016 xucg. All rights reserved.
//  Welcome visiting https://github.com/gukemanbu/XucgPhotoKit

#import "XucgPhotosController.h"
#import <Photos/Photos.h>
#import "XucgPhotoCell.h"
#import "XucgCropController.h"

#define kXucgPhotoCellId @"XucgPhotoCellId"

static CGSize CGSizeScale(CGSize size, CGFloat scale) {
    return CGSizeMake(size.width * scale, size.height * scale);
}

@implementation NSIndexSet (Convenience)

- (NSArray *)qb_indexPathsFromIndexesWithSection:(NSUInteger)section {
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:idx inSection:section]];
    }];
    return indexPaths;
}

@end

@implementation UICollectionView (Convenience)

- (NSArray *)qb_indexPathsForElementsInRect:(CGRect)rect {
    NSArray *allLayoutAttributes = [self.collectionViewLayout layoutAttributesForElementsInRect:rect];
    if (allLayoutAttributes.count == 0) { return nil; }
    
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:allLayoutAttributes.count];
    for (UICollectionViewLayoutAttributes *layoutAttributes in allLayoutAttributes) {
        NSIndexPath *indexPath = layoutAttributes.indexPath;
        [indexPaths addObject:indexPath];
    }
    return indexPaths;
}

@end

@interface XucgPhotosController () <PHPhotoLibraryChangeObserver, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionViewFlowLayout *collectionViewLayout;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) PHFetchResult *fetchResult;
@property (nonatomic, strong) PHCachingImageManager *imageManager;
@property (nonatomic, assign) CGRect previousPreheatRect;

@end

@implementation XucgPhotosController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"相片集合";
    self.view.backgroundColor = [UIColor whiteColor];
    
    _imageManager = [[PHCachingImageManager alloc] init];
    
    // 集合视图
    _collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat spacing = 2;
    _collectionViewLayout.sectionInset = UIEdgeInsetsMake(spacing, 0, 0, 0);
    
    // cell的size，写在这里，快速滑动时，会报内存警告
//    CGFloat itemWidth = (kScreenWidth - spacing * 3) / 4;
//    _collectionViewLayout.itemSize = CGSizeMake(itemWidth, itemWidth);
    
    _collectionViewLayout.minimumInteritemSpacing = 0;
    _collectionViewLayout.minimumLineSpacing = spacing;
    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:_collectionViewLayout];
    _collectionView.backgroundColor = [UIColor whiteColor];
    _collectionView.dataSource = (id<UICollectionViewDataSource>)self;
    _collectionView.delegate = (id<UICollectionViewDelegate>)self;
    [_collectionView registerNib:[UINib nibWithNibName:@"XucgPhotoCell" bundle:nil] forCellWithReuseIdentifier:kXucgPhotoCellId];
    [self.view addSubview:self.collectionView];

    [self resetCachedAssets];
    [self updateFetchRequest];
    [self.collectionView reloadData];

    // 相册变更观察者
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self updateCachedAssets];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateCachedAssets];
}

#pragma mark - CollectionView Delegate & DataSource
-(NSInteger) numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.fetchResult count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    XucgPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kXucgPhotoCellId forIndexPath:indexPath];
    cell.tag = indexPath.item;
    
    // 照片
    PHAsset *asset = self.fetchResult[indexPath.item];
    CGSize itemSize = [(UICollectionViewFlowLayout *)collectionView.collectionViewLayout itemSize];
    CGSize targetSize = CGSizeScale(itemSize, [[UIScreen mainScreen] scale]);
    
    [_imageManager requestImageForAsset:asset
                                 targetSize:targetSize
                                contentMode:PHImageContentModeAspectFill
                                    options:nil
                              resultHandler:^(UIImage *result, NSDictionary *info) {
                                  if (cell.tag == indexPath.item) {
                                      cell.imageView.image = result;
                                  }
                              }];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAsset *asset = self.fetchResult[indexPath.item];
    [_imageManager requestImageForAsset:asset
                             targetSize:PHImageManagerMaximumSize
                            contentMode:PHImageContentModeAspectFill
                                options:nil
                          resultHandler:^(UIImage *result, NSDictionary *info) {
                              XucgCropController *cropController = [[XucgCropController alloc] init];
                              cropController.srcImage = result;
                              [self.navigationController pushViewController:cropController animated:YES];
                          }];
}

- (void)updateFetchRequest {
    if (self.assetCollection) {
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
        self.fetchResult = [PHAsset fetchAssetsInAssetCollection:self.assetCollection options:options];
    } else {
        self.fetchResult = nil;
    }
}

#pragma mark - PHPhotoLibraryChangeObserver
- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    dispatch_async(dispatch_get_main_queue(), ^{
        PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:self.fetchResult];
        
        if (collectionChanges) {
            // Get the new fetch result
            self.fetchResult = [collectionChanges fetchResultAfterChanges];
            
            if (![collectionChanges hasIncrementalChanges] || [collectionChanges hasMoves]) {
                // We need to reload all if the incremental diffs are not available
                [self.collectionView reloadData];
            } else {
                // If we have incremental diffs, tell the collection view to animate insertions and deletions
                [self.collectionView performBatchUpdates:^{
                    NSIndexSet *removedIndexes = [collectionChanges removedIndexes];
                    if ([removedIndexes count]) {
                        [self.collectionView deleteItemsAtIndexPaths:[removedIndexes qb_indexPathsFromIndexesWithSection:0]];
                    }
                    
                    NSIndexSet *insertedIndexes = [collectionChanges insertedIndexes];
                    if ([insertedIndexes count]) {
                        [self.collectionView insertItemsAtIndexPaths:[insertedIndexes qb_indexPathsFromIndexesWithSection:0]];
                    }
                    
                    NSIndexSet *changedIndexes = [collectionChanges changedIndexes];
                    if ([changedIndexes count]) {
                        [self.collectionView reloadItemsAtIndexPaths:[changedIndexes qb_indexPathsFromIndexesWithSection:0]];
                    }
                } completion:NULL];
            }
            
            [self resetCachedAssets];
        }
    });
}

- (void)resetCachedAssets {
    [self.imageManager stopCachingImagesForAllAssets];
    self.previousPreheatRect = CGRectZero;
}

- (void)updateCachedAssets {
    BOOL isViewVisible = [self isViewLoaded] && self.view.window != nil;
    if (!isViewVisible) { return; }
    
    // The preheat window is twice the height of the visible rect
    CGRect preheatRect = self.collectionView.bounds;
    preheatRect = CGRectInset(preheatRect, 0.0, -0.5 * CGRectGetHeight(preheatRect));
    
    // If scrolled by a "reasonable" amount...
    CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
    
    if (delta > CGRectGetHeight(self.collectionView.bounds) / 3.0) {
        // Compute the assets to start caching and to stop caching
        NSMutableArray *addedIndexPaths = [NSMutableArray array];
        NSMutableArray *removedIndexPaths = [NSMutableArray array];
        
        [self computeDifferenceBetweenRect:self.previousPreheatRect andRect:preheatRect addedHandler:^(CGRect addedRect) {
            NSArray *indexPaths = [self.collectionView qb_indexPathsForElementsInRect:addedRect];
            [addedIndexPaths addObjectsFromArray:indexPaths];
        } removedHandler:^(CGRect removedRect) {
            NSArray *indexPaths = [self.collectionView qb_indexPathsForElementsInRect:removedRect];
            [removedIndexPaths addObjectsFromArray:indexPaths];
        }];
        
        NSArray *assetsToStartCaching = [self assetsAtIndexPaths:addedIndexPaths];
        NSArray *assetsToStopCaching = [self assetsAtIndexPaths:removedIndexPaths];
        
        CGSize itemSize = [(UICollectionViewFlowLayout *)self.collectionViewLayout itemSize];
        CGSize targetSize = CGSizeScale(itemSize, [[UIScreen mainScreen] scale]);
        
        [self.imageManager startCachingImagesForAssets:assetsToStartCaching
                                            targetSize:targetSize
                                           contentMode:PHImageContentModeAspectFill
                                               options:nil];
        [self.imageManager stopCachingImagesForAssets:assetsToStopCaching
                                           targetSize:targetSize
                                          contentMode:PHImageContentModeAspectFill
                                              options:nil];
        
        self.previousPreheatRect = preheatRect;
    }
}

- (void)computeDifferenceBetweenRect:(CGRect)oldRect andRect:(CGRect)newRect addedHandler:(void (^)(CGRect addedRect))addedHandler removedHandler:(void (^)(CGRect removedRect))removedHandler {
    if (CGRectIntersectsRect(newRect, oldRect)) {
        CGFloat oldMaxY = CGRectGetMaxY(oldRect);
        CGFloat oldMinY = CGRectGetMinY(oldRect);
        CGFloat newMaxY = CGRectGetMaxY(newRect);
        CGFloat newMinY = CGRectGetMinY(newRect);
        
        if (newMaxY > oldMaxY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY));
            addedHandler(rectToAdd);
        }
        if (oldMinY > newMinY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY));
            addedHandler(rectToAdd);
        }
        if (newMaxY < oldMaxY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY));
            removedHandler(rectToRemove);
        }
        if (oldMinY < newMinY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY));
            removedHandler(rectToRemove);
        }
    } else {
        addedHandler(newRect);
        removedHandler(oldRect);
    }
}

- (NSArray *)assetsAtIndexPaths:(NSArray *)indexPaths {
    if (indexPaths.count == 0) { return nil; }
    
    NSMutableArray *assets = [NSMutableArray arrayWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        if (indexPath.item < self.fetchResult.count) {
            PHAsset *asset = self.fetchResult[indexPath.item];
            [assets addObject:asset];
        }
    }
    return assets;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger numberOfColumns;
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        numberOfColumns = 3;
    } else {
        numberOfColumns = 7;
    }
    
    CGFloat width = (kScreenWidth - 2.0 * (numberOfColumns - 1)) / numberOfColumns;
    
    return CGSizeMake(width, width);
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    // Save indexPath for the last item
    NSIndexPath *indexPath = [[self.collectionView indexPathsForVisibleItems] lastObject];
    
    // 交换collection的宽高
    CGRect newFrame = _collectionView.frame;
    CGFloat oldHeight = newFrame.size.height;
    newFrame.size.height = newFrame.size.width;
    newFrame.size.width = oldHeight;
    _collectionView.frame = newFrame;
    
    // Update layout
    [self.collectionViewLayout invalidateLayout];
    
    // Restore scroll position
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
    }];
}


@end
