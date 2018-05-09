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
