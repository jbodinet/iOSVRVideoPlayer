// ****************************************************************************
// MIT License
//
// Copyright (c) 2018 Joshua E Bodinet
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// ****************************************************************************

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
@property (nonatomic) CGFloat playerPreviewButtonTrackingCustomHeadingOffsetRadiansStart;
@property (nonatomic) BOOL playerPreviewButtonTrackingSuppressButtonBehavior;
@property (nonatomic) BOOL playerPreviewButtonTrackingHijackedByButtonBehavior;
@property (nonatomic) BOOL scrubbing;
@property (nonatomic) BOOL showDragInstructions;

- (IBAction)hitPlayerPreviewButton:(UIButton *)sender;
- (void)hitPlayerPreviewButtonLongPress:(UILongPressGestureRecognizer*)gesture;
- (void)hitPlayerPreviewButtonDoubleTap:(UITapGestureRecognizer*)gesture;
- (void)playerPreviewButtonPinch:(UIPinchGestureRecognizer *)sender;

-(void) pickMovie;
-(void) loadMovieIntoPlayer:(NSURL*)movieURL;
-(void) playerDidFinishPlaying:(NSNotification*)notification;
-(void) updatePreviewOrientation;

- (void) displayLinkReadBuffer:(CADisplayLink *)sender;


@end

