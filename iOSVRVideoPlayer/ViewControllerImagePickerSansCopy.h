//
//  ViewControllerImagePickerSansCopy.h
//  iOSVRVideoPlayer
//
//  Created by Joshua Bodinet on 1/15/20.
//  Copyright © 2020 JoshuaBodinet. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ViewControllerImagePickerSansCopy : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource>

@property (strong, nonatomic) IBOutlet UICollectionView *assetCollectionView;

@property (nonatomic)  NSInteger pickedFileIndex;
@property (strong, nonatomic) NSString *pickedFileAbsoluteURLString;

@end

NS_ASSUME_NONNULL_END
