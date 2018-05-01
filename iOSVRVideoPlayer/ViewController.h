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

#import "AppDelegate.h"
#import "MetalView.h"
#import "PlayerPreviewButton.h"

typedef enum PlayerStateTypes { PlayerState_Playing = 0, PlayerState_Stopped } PlayerState;

@interface ViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate,
                                              AppDelegateTerminationDelegate, PlayerPreviewButtonTouchTrackingDelegate>

@property (strong, nonatomic) IBOutlet MetalView *metalView;
@property (strong, nonatomic) IBOutlet PlayerPreviewButton *playerPreviewButton;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayerItemVideoOutput *playerItemVideoOutput;
@property (strong, nonatomic) CADisplayLink *displayLink;

@property (nonatomic) PlayerState playerState;
@property (nonatomic) BOOL viewControllerHasMadeFirstAppearance;
@property (nonatomic) CGFloat playerPreviewButtonTrackingNormXStart;
@property (nonatomic) BOOL playerPreviewButtonTrackingSuppressButtonBehavior;
@property (nonatomic) BOOL playerPreviewButtonTrackingHijackedByButtonBehavior;

- (IBAction)hitPlayerPreviewButton:(UIButton *)sender;
- (void)hitPlayerPreviewButtonLongPress:(UILongPressGestureRecognizer*)gesture;
- (void)playerPreviewButtonPinch:(UIPinchGestureRecognizer *)sender;

-(void) pickMovie;
-(void) loadMovieIntoPlayer:(NSURL*)movieURL;
-(void) playerDidFinishPlaying:(NSNotification*)notification;
-(void) updatePreviewOrientation;

- (void) displayLinkReadBuffer:(CADisplayLink *)sender;


@end

