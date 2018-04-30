//
//  MetalView.h
//  iOSVRVideoPlayer
//
//  Created by Joshua Bodinet on 4/27/18.
//  Copyright © 2018 JoshuaBodinet. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MetalKit/MetalKit.h>
#import <CoreVideo/CoreVideo.h>

#import "MetalParamWindowFromEquirectOptimized.h"

@interface MetalView : MTKView

@property (strong, nonatomic) id<MTLCommandQueue> commandQueue;
@property (strong, nonatomic) id<MTLLibrary> library;
@property (strong, nonatomic) id<MTLFunction> function;
@property (strong, nonatomic) id<MTLComputePipelineState> filterState;


@property (nonatomic) CVMetalTextureCacheRef textureCache;
@property (nonatomic) CVPixelBufferRef pixelBuffer; 
@property (nonatomic) CFTimeInterval inputTime;
@property (nonatomic) MetalParam metalParam;


-(void)render:(MTKView*)view;

-(MTLSize)threadGroupCount;
-(MTLSize)threadGroups;

@end
