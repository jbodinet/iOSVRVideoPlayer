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

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.appWillTerminateListeners = [NSMutableSet set];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    NSLog(@"Application is shutting down!!!");
    
    // Clear all movies stored in app data, if desired...
    // [self clearMovieFilesFromTmpDirSparingURL:nil];
    
    // go through all listners and tell them the app is terminating
    for(NSObject *obj in self.appWillTerminateListeners)
    {
        if([obj conformsToProtocol:@protocol(AppDelegateTerminationDelegate)])
        {
            NSObject <AppDelegateTerminationDelegate> *del = (NSObject <AppDelegateTerminationDelegate> *)obj;
            [del appWillTerminate];
        }
    }
}

#pragma mark - Termination Cleanup
-(void) clearMovieFilesFromTmpDirSparingURL:(NSURL*)exceptThisURL {
    // Create a local file manager instance and grab the URL of the app temp directory
    NSFileManager *localFileManager = [[NSFileManager alloc] init];
    NSURL *directoryToScan = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    
    // create an enumerator
    NSDirectoryEnumerator *dirEnumerator =
    [localFileManager   enumeratorAtURL:directoryToScan
             includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLIsDirectoryKey,nil]
                                options: NSDirectoryEnumerationSkipsHiddenFiles |
     NSDirectoryEnumerationSkipsSubdirectoryDescendants |
     NSDirectoryEnumerationSkipsPackageDescendants
                           errorHandler:nil];
    
    // walk the enumerator, ditching any mp4 files
    NSError *error;
    for (NSURL *theURL in dirEnumerator)
    {
        if(exceptThisURL != nil && [[theURL absoluteString] isEqualToString:[exceptThisURL absoluteString]])
        {
            continue;
        }
        
        // if url is for an .mp4 file, delete the file
        NSString *extension = [theURL pathExtension];
        if([[extension lowercaseString] isEqualToString:@"mp4"] ||
           [[extension lowercaseString] isEqualToString:@"mov"])
        {
            NSLog(@"AppCloseFileDelete:%@", [theURL path]);
            [localFileManager removeItemAtURL:theURL error:&error];
        }
    }
}


@end
