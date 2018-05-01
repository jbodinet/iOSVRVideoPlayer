//
//  PlayerPreviewButton.m
//  iOSVRVideoPlayer
//
//  Created by Joshua Bodinet on 5/1/18.
//  Copyright © 2018 JoshuaBodinet. All rights reserved.
//

#import "PlayerPreviewButton.h"

@implementation PlayerPreviewButton

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        self.delegate = nil;
    }
    
    return self;
}

-(CGFloat)touchToNormX:(UITouch *)touch {
    CGPoint touchPoint = [touch locationInView:self];
    CGFloat frameWidth = self.frame.size.width;
    
    CGFloat normX = touchPoint.x / (float)frameWidth;
    
    if(normX < 0)
        normX = 0;
    
    if(normX > 1.0)
        normX = 1.0;
    
    return normX;
}

-(BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    if(self.delegate != nil)
    {
        [self.delegate playerPreviewButtonBeginTrackingDidOccurAtNormX:[self touchToNormX:touch]];
    }
    
    return YES;
}

-(BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    if(self.delegate != nil)
    {
        [self.delegate playerPreviewButtonContinueTrackingDidOccurAtNormX:[self touchToNormX:touch]];
    }
    
    return YES;
}

-(void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    if(self.delegate != nil)
    {
        [self.delegate playerPreviewButtonEndTrackingDidOccurAtNormX:[self touchToNormX:touch]];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
