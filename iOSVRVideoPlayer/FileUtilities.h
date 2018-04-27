//
//  FileUtilities.h
//  Perfecto
//
//  Created by Joshua Bodinet on 3/12/18.
//  Copyright © 2018 JoshuaBodinet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface FileUtilities : NSObject

+(NSURL*)tempURL;

+(AVComposition*)compositionFromAsset:(NSURL*)theURL withNormIn:(CGFloat)normIn andNormOut:(CGFloat)normOut;

+(void)copyFileToPhotosLibrary:(NSURL*)theURL withCompletionMessageOverViewController:(UIViewController*)viewController withText:(NSString*)message removeOriginal:(BOOL)removeOriginal;

@end
