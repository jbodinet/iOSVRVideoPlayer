//
//  CollectionViewCellImagePickerSansCopy.m
//  iOSVRVideoPlayer
//
//  Created by Joshua Bodinet on 1/15/20.
//  Copyright © 2020 JoshuaBodinet. All rights reserved.
//

#import "CollectionViewCellImagePickerSansCopy.h"

@implementation CollectionViewCellImagePickerSansCopy

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self)
    {
        self.pickedFileIndex = -1;
    }
    
    return self;
}

@end
