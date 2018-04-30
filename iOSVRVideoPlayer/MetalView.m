//
//  MetalView.m
//  iOSVRVideoPlayer
//
//  Created by Joshua Bodinet on 4/27/18.
//  Copyright © 2018 JoshuaBodinet. All rights reserved.
//

#import "MetalView.h"
#import "SphericalMath.h"

@implementation MetalView

-(instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if(self)
    {
        _pixelBuffer = nil;
        self.landscapeOrientationHFOVRadians = 60.0 * DegToRad;
        
        // init metal related props
        // ******************************
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
        // ***************************************************
        self.motionManager = [[CMMotionManager alloc] init];
        self.motionManager.deviceMotionUpdateInterval = 0.01f;
//        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
//            [self processMotion:motion];
//        }];
        [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical toQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion *motion, NSError *error) {
            [self processMotion:motion];
        }];
    }
    
    return self;
}

-(void) setPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if(_pixelBuffer)
        CVBufferRelease(_pixelBuffer);
    _pixelBuffer = nil;
    _pixelBuffer = pixelBuffer;
    [self setNeedsDisplay];
}

-(void)drawRect:(CGRect)rect {
    @autoreleasepool {
        if(rect.size.width > 0 || rect.size.height > 0)
        {
            [self render:self];
        }
    }
}

-(void)render:(MTKView*)view {
    // pull the dimensions from pixelBuffer
    size_t srcTextureWidth = CVPixelBufferGetWidth(_pixelBuffer);
    size_t srcTextureHeight = CVPixelBufferGetHeight(_pixelBuffer);
    
    // Converts the pixelBuffer in a Metal texture.
    CVMetalTextureRef srcTextureRef;
    id<MTLTexture> srcTexture;
    if(kCVReturnSuccess != CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, _pixelBuffer, nil, MTLPixelFormatBGRA8Unorm, srcTextureWidth, srcTextureHeight, 0, &srcTextureRef))
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
    
    if(_pixelBuffer)
        CVBufferRelease(_pixelBuffer);
    _pixelBuffer = nil;
    
    // create a command buffer
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    // create command encoder
    id<MTLComputeCommandEncoder> commandEncoder = [commandBuffer computeCommandEncoder];
    
    // set the compute pipeline
    [commandEncoder setComputePipelineState:self.filterState];
    
    // The metalParam
    MetalParam metalParam;
    
    // fill in what of the metal params that we can
    metalParam.equirectWidth = (unsigned)srcTextureWidth;
    metalParam.equirectHeight = (unsigned)srcTextureHeight;
    
    // Build up the rest of the necessary information
    // ------------------------------------------------------------
    
    float rotationAxis[4];
    float offsetQuaternion [4], finalQuaternion [4];
    
    // the Space here is mathematical cartesian space with the XY plane on a sheet of paper laying on the table
    // and the Z axis pointing straight up out of the table. Generally computer graphic cartesian space has Z going into and
    // out of the image plane, but with mathematical cartesian space, it is Y that goes into and out of the image plane
    // ---------------------------------------------------------------------------------------------------------------------
    
    
    
    // Handle things differently based upon orientation
    // --------------------------------------------------------------------
    float HFOV = self.landscapeOrientationHFOVRadians;
    
    float dstWidth = self.drawableSize.width;
    float dstHeight = self.drawableSize.height;
    
    float equirectWidth = srcTextureWidth;
    float equirectHeight = srcTextureHeight;
    
    float halfEquirectWidth = equirectWidth * 0.5;
    
    float halfDstWidth = dstWidth * 0.5;
    
    switch(self.orientation)
    {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
        {
            const float pitchOffset = PIOver2;
            
            // must derive HFOV from landscapeFOV and widths and heights.
            // NOTE:
            //  - dstWidth here is the width of the portrait-oriented dst img
            //  - dstHeight here is the width of the landscape-oriented dst img
            HFOV = 2.0 * atan2((0.5 * dstWidth), ((0.5 * dstHeight) / tan(0.5 * self.landscapeOrientationHFOVRadians)));
            
            // set up the only necessary offset, which is pitch rotation is about the Y axis
            // --------------------------------------------------------------------
            rotationAxis[CiX] = 0.0;
            rotationAxis[CiY] = 1.0;
            rotationAxis[CiZ] = 0.0;
            rotationAxis[CiW] = 1.0;
            
            quaternionInitialize(offsetQuaternion, rotationAxis, pitchOffset);
            
            // pull the quaternion from CoreMotion
            // *** WHY DO WE HAVE TO TWEAK THE VALUES AS WE DO???
            // --------------------------------------------------------------------
            finalQuaternion[QiW] = self.quaternion.w;
            finalQuaternion[QiX] = -self.quaternion.z;
            finalQuaternion[QiY] = -self.quaternion.x;
            finalQuaternion[QiZ] = self.quaternion.y;
            
            break;
        }
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
        {
            const float bankOffset = PIOver2;
            
            // can use this as-is
            HFOV = self.landscapeOrientationHFOVRadians;
            
            // set up the only necessary offset, which is pitch rotation is about the Y axis
            // --------------------------------------------------------------------
            rotationAxis[CiX] = 1.0;
            rotationAxis[CiY] = 0.0;
            rotationAxis[CiZ] = 0.0;
            rotationAxis[CiW] = 1.0;
            
            quaternionInitialize(offsetQuaternion, rotationAxis, bankOffset);
            
            // pull the quaternion from CoreMotion
            // *** WHY DO WE HAVE TO TWEAK THE VALUES AS WE DO???
            // --------------------------------------------------------------------
            finalQuaternion[QiW] = self.quaternion.w;
            finalQuaternion[QiZ] = -self.quaternion.z;
            finalQuaternion[QiY] = -self.quaternion.x;
            finalQuaternion[QiX] = self.quaternion.y;
            
            break;
        }
        default:
            break;
    }
    
    // Apply the offset to the quaternion we received from CoreMotion
    // and then turn the whole think into a rotation matrix
    // --------------------------------------------------------------------
    quaternionMultiply(offsetQuaternion, finalQuaternion);
    quaternionToMatrix(finalQuaternion, metalParam.rotationMatrix);
    
    // the HFOV and VFOV of the viewing volume used to generate
    // the dst image when including perspective in the process
    float halfHFOV = (HFOV) / 2.0;
    float halfVFOV = halfHFOV * (dstHeight / (float)dstWidth);
    
    // the density ratios between equirect and dst imagees and vice-versa
    float equirectToDstPixDensity = (halfDstWidth) / ((halfHFOV / PI) * halfEquirectWidth);
    float dstToEquirectPixDensity = 1.0 / equirectToDstPixDensity;
    
    // load up the rest of the metal params
    metalParam.dstToEquirectPixDensity = dstToEquirectPixDensity;
    metalParam.halfHFOV = halfHFOV;
    metalParam.halfVFOV = halfVFOV;
    metalParam.halfHFOV_tangent = tan(halfHFOV);
    metalParam.equirectWidth = equirectWidth;
    metalParam.equirectHeight = equirectHeight;
    metalParam.radius = 1.0;
    
    // create the params buffer
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
    
    // In order to avoid a serious memory leak, must
    // ditch this texture reference here.
    // *** HOWEVER!!! ***
    // Is it fully safe to delete this here? Or
    // do we need to find some callback somewhere
    // where we know the texture ref is 100% certain
    // to be no longer used?
    CVBufferRelease(srcTextureRef);
}

-(void)processMotion:(CMDeviceMotion*)motion {
    //NSLog(@"Roll: %.2f Pitch: %.2f Yaw: %.2f", motion.attitude.roll, motion.attitude.pitch, motion.attitude.yaw);
    //NSLog(@"GX: %.2f GY: %.2f GZ: %.2f", motion.gravity.x, motion.gravity.y, motion.gravity.z);
    //NSLog(@"QW: %0.2f QX: %0.2f QY: %0.2f QZ: %0.2f", motion.attitude.quaternion.w, motion.attitude.quaternion.x, motion.attitude.quaternion.y, motion.attitude.quaternion.z);

    self.quaternion = motion.attitude.quaternion;
}

-(MTLSize)threadsPerGroup {
    return MTLSizeMake(8, 8, 1);
}

-(MTLSize)threadGroups {
    MTLSize groupCount = [self threadsPerGroup];
    return MTLSizeMake((((NSUInteger)self.bounds.size.width) / groupCount.width), (((NSUInteger)self.bounds.size.height) / groupCount.height), 1);
}

@end

