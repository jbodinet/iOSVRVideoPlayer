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

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.viewControllerHasMadeFirstAppearance = NO;
    self.playerState = PlayerState_Stopped;
    
    // add a long press gesture recognizer to player preview button
    [self.playerPreviewButton addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(hitPlayerPreviewButtonLongPress:)]];
}

-(void)viewDidAppear:(BOOL)animated {
    
    if(!self.viewControllerHasMadeFirstAppearance)
    {
        // Player
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.playerLayer.frame = self.playerPreview.bounds;
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        
        [self.playerPreview.layer insertSublayer:self.playerLayer atIndex:0];
        [self.playerPreview layoutIfNeeded];
        
        // register for a notification that that the player has stopped playing because it played until the end
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
        
        // force request to access photos library
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if(status != PHAuthorizationStatusAuthorized)
            {
                NSLog(@"*** Photo Library Access Authorization Not Granted !!! ***");
            }
            else
            {
                [self pickAndLoadMovieIntoPlayer];
            }
        }];
        
        self.viewControllerHasMadeFirstAppearance = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button Handlers

- (IBAction)hitPlayerPreviewButton:(UIButton *)sender {
    NSLog(@"PlayerPreviewButton HIT!!!");
    
    switch(self.playerState)
    {
        case PlayerState_Stopped:
            self.playerState = PlayerState_Playing;
            [self.player play];
            break;
        case PlayerState_Playing:
            self.playerState = PlayerState_Stopped;
            [self.player pause];
            break;
    }
}

- (void)hitPlayerPreviewButtonLongPress:(UILongPressGestureRecognizer*)gesture {
    NSLog(@"PlayerPreviewButton LONG PRESS!!!");
    
    if ( gesture.state == UIGestureRecognizerStateBegan )
    {
        self.playerState = PlayerState_Stopped;
        [self.player pause];
        
        [self pickAndLoadMovieIntoPlayer];
    }
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
        
        [self.player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:mediaURL]];
        
//        AVComposition *composition = [FileUtilities compositionFromAsset:mediaURL withNormIn:0.0 andNormOut:1.0];
//        if(composition)
//        {
//            [self.player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithAsset:composition]];
//        }
        
        self.playerState = PlayerState_Playing;
        [self.player play];
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Player Utils
-(void) pickAndLoadMovieIntoPlayer {
    // pop open the photo library and show videos
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    picker.allowsEditing = NO;
    picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
    [self presentViewController:picker animated:YES completion:nil];
}
-(void) playerDidFinishPlaying:(NSNotification*)notification {
    [self.player seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        self.playerState = PlayerState_Playing;
        [self.player play];
    }];
}


@end
