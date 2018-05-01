//
//  PlayerPreviewButton.h
//  iOSVRVideoPlayer
//
//  Created by Joshua Bodinet on 5/1/18.
//  Copyright © 2018 JoshuaBodinet. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PlayerPreviewButtonTouchTrackingDelegate <NSObject>

@required
-(void)playerPreviewButtonBeginTrackingDidOccurAtNormX:(CGFloat)normX;
-(void)playerPreviewButtonContinueTrackingDidOccurAtNormX:(CGFloat)normX;
-(void)playerPreviewButtonEndTrackingDidOccurAtNormX:(CGFloat)normX;

@end

@interface PlayerPreviewButton : UIButton

@property (weak, nonatomic) id <PlayerPreviewButtonTouchTrackingDelegate> delegate;

-(CGFloat)touchToNormX:(UITouch *)touch;

@end
