//
//  ViewController.m
//  iOSVRVideoPlayer
//
//  Created by Joshua Bodinet on 4/27/18.
//  Copyright © 2018 JoshuaBodinet. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "FileUtilities.h"

static NSString * const fovPrefs = @"FOVPrefs";
const float playerPreviewButtonLongPressSuppressionNormXThreshold = 0.05;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // set ourselves as an AppWillTerminateListener to the AppDelegate
    // -------------------------------------------------------------
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate.appWillTerminateListeners addObject:self];
    
    // set ourselves as delegate to the PlayerPreviewButton
    // -------------------------------------------------------------
    self.playerPreviewButton.delegate = self;
    
    // load prefs
    // -------------------------------------------------------------
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if([userDefaults objectForKey:fovPrefs])
    {
        self.metalView.isPlaying = YES;
        self.metalView.landscapeOrientationHFOVRadians = [userDefaults floatForKey:fovPrefs];
        self.metalView.isPlaying = NO;
    }
    
    self.viewControllerHasMadeFirstAppearance = NO;
    self.playerState = PlayerState_Stopped;
    self.metalView.isPlaying = NO;
    self.playerPreviewButtonTrackingNormXStart = 0.0f;
    self.playerPreviewButtonTrackingSuppressButtonBehavior = NO;
    self.playerPreviewButtonTrackingHijackedByButtonBehavior = NO;

    // add a long press gesture recognizer to player preview button
    [self.playerPreviewButton addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(hitPlayerPreviewButtonLongPress:)]];
    
    // add a pinch gesture recogniser to player preview button
    [self.playerPreviewButton addGestureRecognizer:[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(playerPreviewButtonPinch:)]];
}

-(void)viewDidAppear:(BOOL)animated {
    
    if(!self.viewControllerHasMadeFirstAppearance)
    {
        // Player
        self.player = [[AVPlayer alloc] init];
        
        // Display Link
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkReadBuffer:)];
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.displayLink setPaused:NO]; // *** SHOULD PAUSE THIS WHEN VIEW IS HIDDEN???
        
        // register for a notification that that the player has stopped playing because it played until the end
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
        
        // capture the orientation
        self.metalView.orientation = [[UIApplication sharedApplication] statusBarOrientation];
        
        // try to load the existing movie, and if that doesn't exist, pop up the picker
        AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        NSURL* preloadedMovieURL = [appDelegate firstMovieURL];
        if(nil != preloadedMovieURL)
        {
            [self loadMovieIntoPlayer:preloadedMovieURL];
        }
        else
        {
            // force request to access photos library
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if(status != PHAuthorizationStatusAuthorized)
                {
                    NSLog(@"*** Photo Library Access Authorization Not Granted !!! ***");
                }
                else
                {
                    // if we are granted access, show picker and allow for the loading of a movie
                    [self pickMovie];
                }
            }];
        }
        
        self.viewControllerHasMadeFirstAppearance = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button Handlers

- (IBAction)hitPlayerPreviewButton:(UIButton *)sender {
    //NSLog(@"PlayerPreviewButton HIT!!!");
    
    // if playerPreviewButtonTracking is suppressing all other
    // button behavior, ditch out w/o doing anything
    // --------------------------------------------------------
    if(self.playerPreviewButtonTrackingSuppressButtonBehavior)
        return;
    
    // Handle the button message
    // --------------------------------------------------------
    switch(self.playerState)
    {
        case PlayerState_Stopped:
            self.playerState = PlayerState_Playing;
            self.metalView.isPlaying = YES;
            [self.player play];
            break;
        case PlayerState_Playing:
            self.playerState = PlayerState_Stopped;
            self.metalView.isPlaying = NO;
            [self.player pause];
            
            break;
    }
}

- (void)hitPlayerPreviewButtonLongPress:(UILongPressGestureRecognizer*)gesture {
    //NSLog(@"PlayerPreviewButton LONG PRESS!!!");
    
    // if playerPreviewButtonTracking is suppressing all other
    // button behavior, ditch out w/o doing anything
    // --------------------------------------------------------
    if(self.playerPreviewButtonTrackingSuppressButtonBehavior)
        return;
    
    // However, if this long press snuck in first, then we are
    // hijacking the tracking
    // --------------------------------------------------------
    self.playerPreviewButtonTrackingHijackedByButtonBehavior = YES;
    
    // handle the long press
    // --------------------------------------------------------
    if ( gesture.state == UIGestureRecognizerStateBegan )
    {
        AudioServicesPlaySystemSound(1520); // vibrate
        
        self.playerState = PlayerState_Stopped;
        self.metalView.isPlaying = NO;
        [self.player pause];
        
        [self pickMovie];
    }
}

- (void)playerPreviewButtonPinch:(UIPinchGestureRecognizer *)sender {
    //NSLog(@"PlayerPreviewButton PINCH PRESS Scale:%0.2f", sender.scale);
    
    // if playerPreviewButtonTracking is suppressing all other
    // button behavior, ditch out w/o doing anything
    // --------------------------------------------------------
    if(self.playerPreviewButtonTrackingSuppressButtonBehavior)
        return;
    
    // However, if this long press snuck in first, then we are
    // hijacking the tracking
    // --------------------------------------------------------
    self.playerPreviewButtonTrackingHijackedByButtonBehavior = YES;
    
    float newFOV = self.metalView.landscapeOrientationHFOVRadians / sender.scale;
    
    if(newFOV < landscapeOrientationHFOVRadiansMin)
        newFOV = landscapeOrientationHFOVRadiansMin;
    else if(newFOV > landscapeOrientationHFOVRadiansMax)
        newFOV = landscapeOrientationHFOVRadiansMax;
    
    self.metalView.landscapeOrientationHFOVRadians = newFOV;
    
    // setting the pinch gesture recognizer back to 1.0
    // at the end of this call will dramatically slow down
    // the scaling effect
    [sender setScale:1.0];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {

    if([(NSString*)info[UIImagePickerControllerMediaType] isEqualToString:(NSString*)kUTTypeVideo] ||
       [(NSString*)info[UIImagePickerControllerMediaType] isEqualToString:(NSString*)kUTTypeMovie])
    {
        NSURL *mediaURL = info[UIImagePickerControllerMediaURL];
        
        // ditch all other videos except the one just picked
        // as iOS always copies picked video into app data
        AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDelegate clearMovieFilesFromTmpDirSparingURL:mediaURL];
        
        [self loadMovieIntoPlayer:mediaURL];
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    // as the long press is what popped the image picker, the long press
    // also caused the existing movie to pause. Hence, when we are returning
    // from picker via a cancel, we want to start the movie playing again
    self.playerState = PlayerState_Playing;
    self.metalView.isPlaying = YES;
    [self.player play];
}

#pragma mark - Player Utils
-(void) pickMovie {
    if([PHPhotoLibrary authorizationStatus] != PHAuthorizationStatusAuthorized)
        return;
    
    // pop open the photo library and show videos
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    picker.allowsEditing = NO;
    picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
    [self presentViewController:picker animated:YES completion:nil];
}

-(void) loadMovieIntoPlayer:(NSURL*)movieURL {
    self.playerItem = [AVPlayerItem playerItemWithURL:movieURL];
    self.playerItemVideoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:@{(id)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]}];
    [self.playerItem addOutput:self.playerItemVideoOutput];
    
    [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    
    //        AVComposition *composition = [FileUtilities compositionFromAsset:mediaURL withNormIn:0.0 andNormOut:1.0];
    //        if(composition)
    //        {
    //            [self.player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithAsset:composition]];
    //        }
    
    self.playerState = PlayerState_Playing;
    self.metalView.isPlaying = YES;
    [self.player play];
}

-(void) playerDidFinishPlaying:(NSNotification*)notification {
    [self.player seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        self.playerState = PlayerState_Playing;
        self.metalView.isPlaying = YES;
        [self.player play];
    }];
}

-(void) updatePreviewOrientation {
    // update the bounds of the metal drawable
    self.metalView.drawableSize = CGSizeMake(self.metalView.bounds.size.width, self.metalView.bounds.size.height);
    self.metalView.orientation = [[UIApplication sharedApplication] statusBarOrientation];
}

#pragma mark - CADisplayLink

- (void) displayLinkReadBuffer:(CADisplayLink *)sender {
    CFTimeInterval nextVSync = sender.timestamp + sender.duration;
    CMTime currentTime = [self.playerItemVideoOutput itemTimeForHostTime:nextVSync];
    
    if([self.playerItemVideoOutput hasNewPixelBufferForItemTime:currentTime])
    {
        self.metalView.pixelBuffer = [self.playerItemVideoOutput copyPixelBufferForItemTime:currentTime itemTimeForDisplay:nil];
        self.metalView.inputTime = currentTime.value/(double)currentTime.timescale;
    }
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        //NSLog(@"orientation changed animations occur here!!!");
        
        [self updatePreviewOrientation];
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        //NSLog(@"orientation changed animations completed here!!!");
    }];
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - AppDelegateTerminationDelegate
-(void)appWillTerminate {
    // store prefs
    // -------------------------------------------------------------
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setFloat:self.metalView.landscapeOrientationHFOVRadians forKey:fovPrefs];
}

#pragma mark - PlayerPreviewButtonTouchTrackingDelegate
-(void)playerPreviewButtonBeginTrackingDidOccurAtNormX:(CGFloat)normX {
    NSLog(@"PlayerPreviewBegin:%0.3f", normX);
    
    self.playerPreviewButtonTrackingNormXStart = normX;
    self.playerPreviewButtonTrackingSuppressButtonBehavior = NO;
    self.playerPreviewButtonTrackingHijackedByButtonBehavior = NO;
}

-(void)playerPreviewButtonContinueTrackingDidOccurAtNormX:(CGFloat)normX {
    // always track this
    // ---------------------------------------------------------
    
    
    // however only act on the information IF it is NOT
    // the case that tracking has been hijacked by other
    // button behavior
    // ---------------------------------------------------------
    if(!self.playerPreviewButtonTrackingHijackedByButtonBehavior)
    {
        NSLog(@"PlayerPreviewContinue:%0.3f", normX);
        
        if(!((normX < (self.playerPreviewButtonTrackingNormXStart + playerPreviewButtonLongPressSuppressionNormXThreshold)) &&
             (normX > (self.playerPreviewButtonTrackingNormXStart - playerPreviewButtonLongPressSuppressionNormXThreshold))))
        {
            self.playerPreviewButtonTrackingSuppressButtonBehavior = YES;
        }
        
   
    }
}

-(void)playerPreviewButtonEndTrackingDidOccurAtNormX:(CGFloat)normX {
    NSLog(@"PlayerPreviewEnd:%0.3f", normX);
}

@end
