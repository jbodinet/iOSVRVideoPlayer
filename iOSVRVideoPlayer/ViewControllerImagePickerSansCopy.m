//
//  ViewControllerImagePickerSansCopy.m
//  iOSVRVideoPlayer
//
//  Created by Joshua Bodinet on 1/15/20.
//  Copyright © 2020 JoshuaBodinet. All rights reserved.
//

#import <Photos/Photos.h>

#import "ViewControllerImagePickerSansCopy.h"
#import "CollectionViewCellImagePickerSansCopy.h"

static NSString * const reuseIdentifier = @"ImagePickerSansCopyCell";

@interface ViewControllerImagePickerSansCopy ()

@end

@implementation ViewControllerImagePickerSansCopy

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.assetCollectionView.delegate = self;
    self.assetCollectionView.dataSource = self;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    PHFetchResult *results = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeVideo options:nil];
    return [results count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PHFetchResult *results = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeVideo options:nil];
    PHAsset *asset = [results objectAtIndex:[indexPath row]];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    PHVideoRequestOptions *options = [PHVideoRequestOptions new];
    __block AVAsset *resultAsset = nil;
    [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset * _Nullable avAsset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        resultAsset = avAsset;
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:resultAsset];
    [imageGenerator setAppliesPreferredTrackTransform:YES];
    
    CMTime time = CMTimeMake(0, resultAsset.duration.timescale);
    UIImage* image = [UIImage imageWithCGImage:[imageGenerator copyCGImageAtTime:time actualTime:nil error:nil]];
    
    CollectionViewCellImagePickerSansCopy *theCell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier
                                                                                             forIndexPath:indexPath];
    theCell.imageView.image = image;
    
    // add a border on the cell -- needs #import<QuartzCore/QuartzCore.h>
    //    theCell.layer.borderWidth = 1.0f;
    //    theCell.layer.borderColor = [UIColor grayColor].CGColor;
    
    return theCell;
    
    /*
    FileListQueueElement *element = [[self.fileListDelegate fileList] objectAtIndex:[indexPath row]];
    NSURL *theURL = [element url];
    AVCaptureDevicePosition thePosition = [element cameraPosition];
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:theURL options:nil];
    
    AVAssetImageGenerator* imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    [imageGenerator setAppliesPreferredTrackTransform:YES]; // must set this to YES to get portrait images showing in portrait orientation!!!
    
    CMTime time = CMTimeMake((asset.duration.value * [element normIn]), asset.duration.timescale);
    UIImage* image = [UIImage imageWithCGImage:[imageGenerator copyCGImageAtTime:time actualTime:nil error:nil]];
    
    CollectionViewCellPlayerAssetDrawer *theCell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier
                                                                                             forIndexPath:indexPath];
    theCell.imageView.image = image;
    
    if(thePosition == AVCaptureDevicePositionFront && self.flipSelfieCameraPlaybackHorz)
    {
        [theCell.imageView setTransform:CGAffineTransformMakeScale( -1.0, 1.0)];
    }
    else
    {
        [theCell.imageView setTransform:CGAffineTransformMakeScale( 1.0, 1.0)];
    }
    
    // add a border on the cell -- needs #import<QuartzCore/QuartzCore.h>
    //    theCell.layer.borderWidth = 1.0f;
    //    theCell.layer.borderColor = [UIColor grayColor].CGColor;
    
    return theCell;
     */
}

@end
