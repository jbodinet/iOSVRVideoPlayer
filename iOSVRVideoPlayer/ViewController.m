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

#import "ViewController.h"
#import "ViewControllerImagePickerSansCopy.h"
#import "AppDelegate.h"
#import "FileUtilities.h"

static NSString * const fovPrefs = @"FOVPrefs";
static NSString * const showDragInstructionsPrefs = @"DragInstructionsPrefs";
const float playerPreviewButtonSuppressionNormXThreshold = 0.05;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self prefersStatusBarHidden];
    [self.navigationController setNeedsStatusBarAppearanceUpdate];
    
    // set ourselves as an AppWillTerminateListener to the AppDelegate
    // -------------------------------------------------------------
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate.appWillTerminateListeners addObject:self];
    
    // set ourselves as delegate to the PlayerPreviewButton
    // -------------------------------------------------------------
    self.playerPreviewButton.delegate = self;
    
    // set defaults
    // -------------------------------------------------------------
    self.viewControllerHasMadeFirstAppearance = NO;
    self.playerState = PlayerState_Stopped;
    self.metalView.isPlaying = NO;
    self.playerPreviewButtonTrackingNormXStart = 0.0f;
    self.playerPreviewButtonTrackingCustomHeadingOffsetRadiansStart = 0.0f;
    self.playerPreviewButtonTrackingSuppressButtonBehavior = NO;
    self.playerPreviewButtonTrackingHijackedByButtonBehavior = NO;
    self.scrubbing = NO;
    self.showDragInstructions = YES;
    
    // load prefs
    // -------------------------------------------------------------
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if([userDefaults objectForKey:fovPrefs])
    {
        self.metalView.isPlaying = YES;
        self.metalView.landscapeOrientationHFOVRadians = [userDefaults floatForKey:fovPrefs];
        self.metalView.isPlaying = NO;
    }

    if([userDefaults objectForKey:showDragInstructionsPrefs])
    {
        self.showDragInstructions = [userDefaults boolForKey:showDragInstructionsPrefs];
    }
    
    // add a long press gesture recognizer to player preview button
    [self.playerPreviewButton addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(hitPlayerPreviewButtonLongPress:)]];
    
    // add a double tap gesture recognizer to playerr preview button
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hitPlayerPreviewButtonDoubleTap:)];
    tapGestureRecognizer.numberOfTapsRequired = 2;
    [self.playerPreviewButton addGestureRecognizer:tapGestureRecognizer];
    
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
        
        // update the orientation to ensure
        // we start correctly
        [self updatePreviewOrientation];
        
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
    
    // However, if this button event snuck in first, then we are
    // hijacking the tracking
    // --------------------------------------------------------
    self.playerPreviewButtonTrackingHijackedByButtonBehavior = YES;
    
    // say we are not scrubbing
    // --------------------------------------------------------
    self.scrubbing = NO;
    
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
    
    // say we are not scrubbing
    // --------------------------------------------------------
    self.scrubbing = NO;
    
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

- (void)hitPlayerPreviewButtonDoubleTap:(UITapGestureRecognizer*)gesture {
    // stop the movie
    self.playerState = PlayerState_Stopped;
    self.metalView.isPlaying = NO;
    [self.player pause];
    
    // say we are now scrubbing
    self.scrubbing = YES;
}

- (void)playerPreviewButtonPinch:(UIPinchGestureRecognizer *)sender {
    //NSLog(@"PlayerPreviewButton PINCH PRESS Scale:%0.2f", sender.scale);
    
    // if playerPreviewButtonTracking is suppressing all other
    // button behavior, ditch out w/o doing anything
    // --------------------------------------------------------
    if(self.playerPreviewButtonTrackingSuppressButtonBehavior)
        return;
    
    // However, if this pinch operation snuck in first, then we are
    // hijacking the tracking
    // --------------------------------------------------------
    self.playerPreviewButtonTrackingHijackedByButtonBehavior = YES;
    
    // say we are not scrubbing
    // --------------------------------------------------------
    self.scrubbing = NO;
    
    // handle the pinch
    // --------------------------------------------------------
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
    // NOTE: Usage of the stock UIImagePickerController REQUIRES that the chosen
    //       asset gets COPIED into the AppData for the App. 
#if 0
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    picker.allowsEditing = NO;
    picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
    [self presentViewController:picker animated:YES completion:nil];
#endif
    
    [self performSegueWithIdentifier:@"showImagePickerSansCopy" sender:self];
}

-(void) loadMovieIntoPlayer:(NSURL*)movieURL {
    self.playerItem = [AVPlayerItem playerItemWithURL:movieURL];
    self.playerItemVideoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:@{(id)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]}];
    [self.playerItem addOutput:self.playerItemVideoOutput];
    
    [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
    
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

#pragma mark - AppDelegateTerminationDelegate
-(void)appWillTerminate {
    // store prefs
    // -------------------------------------------------------------
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setFloat:self.metalView.landscapeOrientationHFOVRadians forKey:fovPrefs];
    [userDefaults setBool:self.showDragInstructions forKey:showDragInstructionsPrefs];
}

#pragma mark - PlayerPreviewButtonTouchTrackingDelegate
-(void)playerPreviewButtonBeginTrackingDidOccurAtNormX:(CGFloat)normX {
    //NSLog(@"PlayerPreviewBegin:%0.3f", normX);
    
    // take all of our initial samples
    // ---------------------------------------------------------
    self.playerPreviewButtonTrackingNormXStart = normX;
    self.playerPreviewButtonTrackingCustomHeadingOffsetRadiansStart = self.metalView.customHeadingOffsetRadians;
    
    // clear out all of our flags
    // ---------------------------------------------------------
    self.playerPreviewButtonTrackingSuppressButtonBehavior = NO;
    self.playerPreviewButtonTrackingHijackedByButtonBehavior = NO;
}

-(void)playerPreviewButtonContinueTrackingDidOccurAtNormX:(CGFloat)normX {
    // if we surpass the threshold necessary to start considering this a valid tracking move
    if(!((normX < (self.playerPreviewButtonTrackingNormXStart + playerPreviewButtonSuppressionNormXThreshold)) &&
         (normX > (self.playerPreviewButtonTrackingNormXStart - playerPreviewButtonSuppressionNormXThreshold))))
    {
        self.playerPreviewButtonTrackingSuppressButtonBehavior = YES;
    }
    else
    {
        // until we reach the above tested threshold, we do nothing else
        // in this entire function--and thus just 'return' here...
        if(!self.playerPreviewButtonTrackingSuppressButtonBehavior)
            return;
    }
    
    // show drag instructions if we have not yet
    if(self.showDragInstructions)
    {
        // hold on to the original player state
        __block PlayerState originalPlayerState = self.playerState;
        
        // stop playback
        self.playerState = PlayerState_Stopped;
        self.metalView.isPlaying = NO;
        [self.player pause];
        
        // show message
        NSString *message = @"•Drag to reorient heading\n•Double tap, then drag to scrub";
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Drag Instructions" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // if the original state was playing, recommence playback
            if(originalPlayerState == PlayerState_Playing)
            {
                self.playerState = PlayerState_Playing;
                self.metalView.isPlaying = YES;
                [self.player play];
            }
        }];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
        
        self.showDragInstructions = NO;
    }
    
    // if we are presently scrubbing (which is a special case)
    if(self.scrubbing)
    {
        [self.player seekToTime:CMTimeMake(self.player.currentItem.asset.duration.value * normX, self.player.currentItem.asset.duration.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }
    // otherwise we handle the default case
    else
    {
        // only act on the tracking information IF it is NOT
        // the case that tracking has been hijacked by other
        // button behavior
        // ---------------------------------------------------------
        if(!self.playerPreviewButtonTrackingHijackedByButtonBehavior)
        {
            //NSLog(@"PlayerPreviewContinue:%0.3f", normX);
            
            // find out our current norm delta between where the tracking started,
            // and where we are now
            float currentNormDelta = normX - self.playerPreviewButtonTrackingNormXStart;
            
            // turn that norm delta into a delta in radians, based upon WHATEVER is our
            // current HFOV (regardless as to whether we are in portrait or landscape)
            float currentRadDelta = self.metalView.currentHFOVRadians * currentNormDelta;
            
            // using the value of what the 'customHeadingOffsetRadians' was at the start of this
            // tracking operation, tack on the additional delta that is presently under consideration
            self.metalView.customHeadingOffsetRadians = self.playerPreviewButtonTrackingCustomHeadingOffsetRadiansStart + currentRadDelta;
        }
    }
}

-(void)playerPreviewButtonEndTrackingDidOccurAtNormX:(CGFloat)normX {
    //NSLog(@"PlayerPreviewEnd:%0.3f", normX);
}

#pragma mark - Standard UIView Overrides
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

#pragma mark - Segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showImagePickerSansCopy"])
    {
        // proper handling of sender object
        // -----------------------------------------------------
        if(sender != self)
        {
            return;
        }
        
        
        
    }
}

- (IBAction)showImagePickerSansCopyUnwind:(UIStoryboardSegue*)unwindSegue {
    NSLog(@"showImagePickerSansCopyUnwind!!!");
    
    if([unwindSegue.sourceViewController isKindOfClass:[ViewControllerImagePickerSansCopy class]])
    {
        ViewControllerImagePickerSansCopy* imagePickerSansCopy = (ViewControllerImagePickerSansCopy*)unwindSegue.sourceViewController;
        
        NSInteger pickedFileIndex = imagePickerSansCopy.pickedFileIndex;
        NSString *pickedFileAbsoluteURLString = [NSString stringWithString:imagePickerSansCopy.pickedFileAbsoluteURLString];
        
        NSLog(@"Picked File Idx:%d URL:%@", (int)pickedFileIndex, pickedFileAbsoluteURLString);
    }
}

@end
