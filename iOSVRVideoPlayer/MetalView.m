//
//  MetalView.m
//  iOSVRVideoPlayer
//
//  Created by Joshua Bodinet on 4/27/18.
//  Copyright © 2018 JoshuaBodinet. All rights reserved.
//

#import "MetalView.h"

@implementation MetalView

-(instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if(self)
    {
        NSError *errors;
        
        // create default metal device
        self.device = MTLCreateSystemDefaultDevice(); // *** DO WE NEED TO DO THIS HERE???
                                                      // 'device' is part of the MTKView base class, and so it
                                                      // may already be properly created in the above [super initWithCoder:coder];
        
        // create the metal command queue
        self.commandQueue = [self.device newCommandQueue];
        
        // create the metal library
        self.library = [self.device newDefaultLibrary];
        
        // pull the function
        self.function =  [self.library newFunctionWithName:@"kernelFunctionEquirectangularToRectilinear"];
        
        // create the compute pipeline state
        self.filterState = [self.device newComputePipelineStateWithFunction:self.function error:&errors];
        
        // create the texture cache
        CVMetalTextureCacheRef textCache;
        if(kCVReturnSuccess != CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, self.device, nil, &textCache))
        {
            NSLog(@"CANNOT CREATE METAL TEXTURE CACHE!!!");
        }
        self.textureCache = textCache;
        
        // enable the current drawable texture read/write.
        self.framebufferOnly = NO;
        
        // disable drawable auto-resize.
        self.autoResizeDrawable = false;
        
        // set the content mode to aspect fit.
        self.contentMode = UIViewContentModeScaleAspectFit; // *** IS THIS CORRECT FOR WHAT WE WANT?
        
        // Change drawing mode based on setNeedsDisplay().
        self.enableSetNeedsDisplay = YES;
        self.paused = YES;
        
        // Set the content scale factor to the screen scale.
        self.contentScaleFactor = [UIScreen mainScreen].scale;
        
        // Set the size of the drawable.
        self.drawableSize = CGSizeMake(self.bounds.size.width, self.bounds.size.height);
        
        // register for motion
        self.motionManager = [[CMMotionManager alloc] init];
        self.motionManager.deviceMotionUpdateInterval = 0.1f;
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
            [self processMotion:motion];
        }];
    }
    
    return self;
}

-(void) setPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    self->_pixelBuffer = pixelBuffer;
    [self setNeedsDisplay];
}

-(void)drawRect:(CGRect)rect {
    if(rect.size.width > 0 || rect.size.height > 0)
    {
        [self render:self];
    }
}

-(void)render:(MTKView*)view {
    // grab local pixelBuffer ref
    CVPixelBufferRef pixelBuffer = self.pixelBuffer;
    if(!pixelBuffer)
    {
        NSLog(@"render: called without pixelBuffer!!!");
        return;
    }
    
    // pull the dimensions from pixelBuffer
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    // Converts the pixelBuffer in a Metal texture.
    CVMetalTextureRef srcTextureRef;
    id<MTLTexture> srcTexture;
    if(kCVReturnSuccess != CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache, pixelBuffer, nil, MTLPixelFormatBGRA8Unorm, width, height, 0, &srcTextureRef))
    {
        NSLog(@"render: called CVMetalTextureCacheCreateTextureFromImage() failed!!!");
        return;
    }
    
    // get the srcTexture out of the srcTextureRef
    srcTexture = CVMetalTextureGetTexture(srcTextureRef);
    
    // Check if Core Animation provided a drawable.
    id<CAMetalDrawable> drawable = self.currentDrawable;
    if(!drawable)
    {
        NSLog(@"render: called without drawable!!!");
        return;
    }
    
    // create a command buffer
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    // create command encoder
    id<MTLComputeCommandEncoder> commandEncoder = [commandBuffer computeCommandEncoder];
    
    // set the compute pipeline
    [commandEncoder setComputePipelineState:self.filterState];
    
    // fill in what of the metal params that we can
    _metalParam.equirectWidth = (unsigned)width;
    _metalParam.equirectHeight = (unsigned)height;
    
    // TEST ONLY
    // ******************************
    // ******************************
    // ******************************
    // Build up the rest of the necessary information
    // ------------------------------------------------------------
#if 0
    float headingOffset = -PI;
    float pitchOffset = 0;
    float bankOffset = 0;
    
    float heading = 45 * DegToRad;
    float pitch = 45 * DegToRad;
    float bank = 0 * DegToRad;
    
    float HFOV = 90.0 * DegToRad;
    
    equirectWidth = decodedWidth;
    equirectHeight = decodedHeight;
    
    halfEquirectWidth = equirectWidth * 0.5;
    halfEquirectHeight = equirectHeight * 0.5;
    
    halfDstWidth = dstWidth * 0.5;
    halfDstHeight = dstHeight * 0.5;
    
    // the HFOV and VFOV of the viewing volume used to generate
    // the dst image when including perspective in the process
    halfHFOV = (HFOV) / 2.0;
    halfVFOV = halfHFOV * (dstHeight / (float)dstWidth);
    
    // the density ratios between equirect and dst imagees and vice-versa
    equirectToDstPixDensity = (halfDstWidth) / ((halfHFOV / PI) * halfEquirectWidth);
    dstToEquirectPixDensity = 1.0 / equirectToDstPixDensity;
    
    // the Space here is mathematical cartesian space with the XY plane on a sheet of paper laying on the table
    // and the Z axis pointing straight up out of the table. Generally computer graphic cartesian space has Z going into and
    // out of the image plane, but with mathematical cartesian space, it is Y that goes into and out of the image plane
    // ---------------------------------------------------------------------------------------------------------------------
    
    // ----------------------------------------------------------
    // ----------------------------------------------------------
    // set up the rotation matrix using quaternions. This
    // occurs by successively storing up rotations in the
    // 'totalQuaternion', though to do so we have to prepare
    // the axis of each rotation as we go.
    // ----------------------------------------------------------
    // ----------------------------------------------------------
    
    // heading rotation is about the Z axis
    // --------------------------------------------------------------------
    rotationAxis[CiX] = 0.0;
    rotationAxis[CiY] = 0.0;
    rotationAxis[CiZ] = 1.0;
    rotationAxis[CiW] = 1.0;
    
    quaternionInitialize(headingQuaternion, rotationAxis, heading - headingOffset);
    
    // pitch rotation is about the Y axis
    // --------------------------------------------------------------------
    rotationAxis[CiX] = 0.0;
    rotationAxis[CiY] = 1.0;
    rotationAxis[CiZ] = 0.0;
    rotationAxis[CiW] = 1.0;
    
    quaternionInitialize(pitchQuaternion, rotationAxis, pitch - pitchOffset);
    
    // bank rotation is about the X axis
    // --------------------------------------------------------------------
    rotationAxis[CiX] = 1.0;
    rotationAxis[CiY] = 0.0;
    rotationAxis[CiZ] = 0.0;
    rotationAxis[CiW] = 1.0;
    
    quaternionInitialize(bankQuaternion, rotationAxis, bank - bankOffset);
    
    // build up the total rotation and store it in the rotationMatrix in the metal param
    quaternionMultiply(headingQuaternion, pitchQuaternion);
    quaternionMultiply(pitchQuaternion, bankQuaternion);
    quaternionToMatrix(bankQuaternion, _metalParam.rotationMatrix);
#endif
    // TEST ONLY OVER
    // ******************************
    // ******************************
    // ******************************
    
    // create the params buffer
    MetalParam metalParam = self.metalParam;
    id<MTLBuffer> paramsBuffer = [self.device newBufferWithBytes:&(metalParam) length:sizeof(metalParam) options:MTLResourceOptionCPUCacheModeDefault];
    
    // set the input texture, the output texture, and the params buffer
    [commandEncoder setTexture:srcTexture atIndex:0]; // SRC TEXTURE
    [commandEncoder setTexture:drawable.texture atIndex:1];
    [commandEncoder setBuffer:paramsBuffer offset:0 atIndex:0];
    
    // encode a threadgroup's execution of a compute function
    [commandEncoder dispatchThreadgroups:[self threadGroups] threadsPerThreadgroup:[self threadsPerGroup]];
    
    // end the encoding of the command.
    [commandEncoder endEncoding];
    
    // Register the current drawable for rendering.
    [commandBuffer presentDrawable:drawable];
    
    // Commit the command buffer for execution.
    [commandBuffer commit];
}

-(void)processMotion:(CMDeviceMotion*)motion {
    NSLog(@"Roll: %.2f Pitch: %.2f Yaw: %.2f", motion.attitude.roll, motion.attitude.pitch, motion.attitude.yaw);
}

-(MTLSize)threadsPerGroup {
    return MTLSizeMake(8, 8, 1);
}

-(MTLSize)threadGroups {
    MTLSize groupCount = [self threadsPerGroup];
    return MTLSizeMake((((NSUInteger)self.bounds.size.width) / groupCount.width), (((NSUInteger)self.bounds.size.height) / groupCount.height), 1);
}

@end

