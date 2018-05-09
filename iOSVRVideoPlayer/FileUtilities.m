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

#import "FileUtilities.h"

#import <Photos/Photos.h>

@implementation FileUtilities

+(NSURL*)tempURL {
    NSString *tempDir = NSTemporaryDirectory();
    
    if(tempDir)
    {
        NSString *fileName = [[[NSUUID UUID]UUIDString] stringByAppendingPathExtension:@"mp4"];
        return [NSURL fileURLWithPath:[tempDir stringByAppendingPathComponent:fileName]];
    }
    
    return nil;
}

+(AVComposition*)compositionFromAsset:(NSURL*)theURL withNormIn:(CGFloat)normIn andNormOut:(CGFloat)normOut {
    // validate
    if(normIn > normOut)
    {
        CGFloat temp = normIn;
        normIn = normOut;
        normOut = temp;
    }
    
    if(normIn < 0)
    {
        normIn = 0.0f;
    }
    
    if(normOut > 1)
    {
        normOut = 1.0f;
    }
    
    NSError *error = nil;
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:theURL options:nil];
    if(urlAsset && urlAsset.tracks.lastObject)
    {
        CMTimeRange existingTimeRange = urlAsset.tracks.lastObject.timeRange;
        
        CMTimeRange newTimeRange = CMTimeRangeMake(CMTimeMake(existingTimeRange.duration.value * normIn, existingTimeRange.duration.timescale),
                                                   CMTimeMake(existingTimeRange.duration.value * (normOut - normIn), existingTimeRange.duration.timescale));
        
        AVMutableComposition *mutableComposition = [AVMutableComposition composition];
        [mutableComposition insertTimeRange:newTimeRange ofAsset:urlAsset atTime:CMTimeMake(0, newTimeRange.duration.timescale) error:&error];
        
        AVMutableCompositionTrack *compositionTrack = [mutableComposition tracksWithMediaType:AVMediaTypeVideo].lastObject;
        if(compositionTrack)
        {
            CGAffineTransform xfrm = [urlAsset tracksWithMediaType:AVMediaTypeVideo].lastObject.preferredTransform;
            [compositionTrack setPreferredTransform:xfrm];
            
            AVComposition *composition = [mutableComposition copy];
            return composition;
        }
    }
    
    return nil;
}

+(void)copyFileToPhotosLibrary:(NSURL*)theURL withCompletionMessageOverViewController:(UIViewController*)viewController withText:(NSString*)message removeOriginal:(BOOL)removeOriginal {
    __block PHObjectPlaceholder *placeholder;
    __block NSString* localId;
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest* createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:theURL];
        placeholder = [createAssetRequest placeholderForCreatedAsset];
        localId = [placeholder localIdentifier];
    } completionHandler:^(BOOL success, NSError *error) {
        if (success)
        {
            if(removeOriginal)
            {
                [[NSFileManager defaultManager] removeItemAtPath:[theURL path] error:NULL];
            }
            
            if(viewController && message)
            {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"File Save" message:message preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    //BUTTON OK CLICK EVENT
                    NSLog(@"+++ File Saved to Photo Album:%@", [theURL path]);
                }];
                [alert addAction:ok];
                [viewController presentViewController:alert animated:YES completion:nil];
            }
        }
        else
        {
            NSLog(@"%@", error);
        }
    }];
}

@end
