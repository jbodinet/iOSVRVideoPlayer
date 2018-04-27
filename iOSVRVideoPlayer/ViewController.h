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

typedef enum PlayerStateTypes { PlayerState_Playing = 0, PlayerState_Stopped } PlayerState;

@interface ViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *playerPreview;
@property (strong, nonatomic) IBOutlet UIButton *playerPreviewButton;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;

@property (nonatomic) PlayerState playerState;
@property (nonatomic) BOOL viewControllerHasMadeFirstAppearance;

- (IBAction)hitPlayerPreviewButton:(UIButton *)sender;
- (void)hitPlayerPreviewButtonLongPress:(UILongPressGestureRecognizer*)gesture;

-(void) pickAndLoadMovieIntoPlayer;
-(void) playerDidFinishPlaying:(NSNotification*)notification;
-(void) updatePreviewOrientation;


@end

