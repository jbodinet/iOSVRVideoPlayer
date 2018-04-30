//
//  AppDelegate.h
//  iOSVRVideoPlayer
//
//  Created by Joshua Bodinet on 4/27/18.
//  Copyright © 2018 JoshuaBodinet. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AppDelegateTerminationDelegate

@required
-(void)appWillTerminate;

@end;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSMutableSet *appWillTerminateListeners;

-(NSURL*) firstMovieURL;
-(void) clearMovieFilesFromTmpDirSparingURL:(NSURL*)exceptThisURL;



@end

