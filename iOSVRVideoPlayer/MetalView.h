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
#import <CoreMotion/CoreMotion.h>

#import "MetalParamWindowFromEquirectOptimized.h"

@interface MetalView : MTKView

@property (strong, nonatomic) id<MTLCommandQueue> commandQueue;
@property (strong, nonatomic) id<MTLLibrary> library;
@property (strong, nonatomic) id<MTLFunction> function;
@property (strong, nonatomic) id<MTLComputePipelineState> filterState;
@property (strong, nonatomic) CMMotionManager *motionManager;

@property (nonatomic) CVMetalTextureCacheRef textureCache;
@property (nonatomic) CVPixelBufferRef pixelBuffer; 
@property (nonatomic) CFTimeInterval inputTime;
@property (nonatomic) MetalParam metalParam;


-(void)render:(MTKView*)view;

-(void)processMotion:(CMDeviceMotion*)motion;

-(MTLSize)threadsPerGroup;
-(MTLSize)threadGroups;

@end
