//
//  ViewController.m
//  iOSVRVideoPlayer
//
//  Created by Joshua Bodinet on 4/27/18.
//  Copyright © 2018 JoshuaBodinet. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.viewControllerHasMadeFirstAppearance = NO;
    
    
    // add a long press gesture recognizer to player preview button
    [self.playerPreview addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(hitPlayerPreviewButtonLongPress:)]];
}

-(void)viewDidAppear:(BOOL)animated {
    
    if(!self.viewControllerHasMadeFirstAppearance)
    {
        // force request to access photos library
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if(status != PHAuthorizationStatusAuthorized)
            {
                NSLog(@"*** Photo Library Access Authorization Not Granted !!! ***");
            }
            else
            {
                // pop open the photo library and show videos
                UIImagePickerController *picker = [[UIImagePickerController alloc] init];
                picker.delegate = self;
                picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
                picker.allowsEditing = NO;
                picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
                [self presentViewController:picker animated:YES completion:nil];
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
    
}

- (void)hitPlayerPreviewButtonLongPress:(UILongPressGestureRecognizer*)gesture {
    
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
        
        NSLog(@"%@", mediaURL);
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}


@end
