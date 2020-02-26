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
    
    self.pickedFileIndex = -1;
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Button Handlers

- (IBAction)cancelButtonHit:(UIButton *)sender {
    self.pickedFileIndex = -1; // tell main controller that user did NOT select a video
    
    // unwind back to standard view controller
    [self performSegueWithIdentifier:@"showImagePickerSansCopyUnwind" sender:self];
}

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
    theCell.pickedFileIndex = [indexPath row];
    
    if([resultAsset isKindOfClass:[AVURLAsset class]])
    {
        AVURLAsset *urlAsset = (AVURLAsset*)resultAsset;
        theCell.pickedFileAbsoluteURLString = [NSString stringWithString:[urlAsset.URL absoluteString]];
    }
    
    // add a border on the cell -- needs #import<QuartzCore/QuartzCore.h>
    //    theCell.layer.borderWidth = 1.0f;
    //    theCell.layer.borderColor = [UIColor grayColor].CGColor;
    
    return theCell;
}

#pragma mark - <UICollectionViewDelegate>

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // get the selected Cell
    CollectionViewCellImagePickerSansCopy *cell = (CollectionViewCellImagePickerSansCopy *)[collectionView cellForItemAtIndexPath:indexPath];
    
    // grab the selection info
    self.pickedFileIndex = cell.pickedFileIndex;
    self.pickedFileAbsoluteURLString = cell.pickedFileAbsoluteURLString;
    
    // unwind back to standard view controller
    [self performSegueWithIdentifier:@"showImagePickerSansCopyUnwind" sender:self];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showImagePickerSansCopyUnwind"])
    {
        if(sender == self)
        {
            
        }
    }
}

@end
