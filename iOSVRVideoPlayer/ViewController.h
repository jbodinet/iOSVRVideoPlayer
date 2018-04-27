//
//  ViewController.h
//  iOSVRVideoPlayer
//
//  Created by Joshua Bodinet on 4/27/18.
//  Copyright © 2018 JoshuaBodinet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface ViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *playerPreview;
@property (strong, nonatomic) IBOutlet UIButton *playerPreviewButton;

@property (nonatomic) BOOL viewControllerHasMadeFirstAppearance;

- (IBAction)hitPlayerPreviewButton:(UIButton *)sender;
- (void)hitPlayerPreviewButtonLongPress:(UILongPressGestureRecognizer*)gesture;


@end

