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

#import "MetalView.h"
#import "SphericalMath.h"

const float landscapeOrientationHFOVRadiansMin = 15 * ((float) ( PI_RAW / 180.0 ));
const float landscapeOrientationHFOVRadiansMax = 120 * ((float) ( PI_RAW / 180.0 ));

@implementation MetalView

-(instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if(self)
    {
        _pixelBuffer = nil;
        _isPlaying = NO;
        _landscapeOrientationHFOVRadians = 60.0 * DegToRad;
        _customHeadingOffsetRadians = 0.0f;
        
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
        self.motionManager.deviceMotionUpdateInterval = 1.0 / 30.0f;
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

-(void) setLandscapeOrientationHFOVRadians:(float)landscapeOrientationHFOVRadians {
    _landscapeOrientationHFOVRadians = landscapeOrientationHFOVRadians;
    
    if(_isPlaying == NO)
    {
        [self setNeedsDisplay];
    }
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
        
        // clear view to black
        // ------------------------------------------------------
        // Check if Core Animation provided a drawable.
        id<CAMetalDrawable> drawable = self.currentDrawable;
        if(drawable)
        {
            view.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
            
            // create a command buffer
            id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
            
            // create command encoder
            id<MTLComputeCommandEncoder> commandEncoder = [commandBuffer computeCommandEncoder];
            
            // set the compute pipeline
            [commandEncoder setComputePipelineState:self.filterState];
            
            // end the encoding of the command.
            [commandEncoder endEncoding];
            
            // Register the current drawable for rendering.
            [commandBuffer presentDrawable:drawable];
            
            // Commit the command buffer for execution.
            [commandBuffer commit];
        }
        
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
    
    // The metalParam
    MetalParam metalParam;
    
    // fill in what of the metal params that we can
    metalParam.equirectWidth = (unsigned)srcTextureWidth;
    metalParam.equirectHeight = (unsigned)srcTextureHeight;
    
    // Build up the rest of the necessary information
    // ------------------------------------------------------------
    
    float rotationAxis[4];
    float finalQuaternion [4];
    
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
    
    // set up the necessary offsets, which are about the Y axis and about the Z axis
    // ------------------------------------------------------------------------------
    const float offsetY = PIOver2; // can be constant, which fixes gymbol issue as iPhone is in a neutral position when laying on a table
    float offsetZ = 0; // is a different value for different orientations, so that image sphere remains pinned over orientation switching
    float offsetYQuaternion [4], offsetZQuaternion [4];
    
    // load offsetY into offsetYQuaternion
    // -------------------------------------
    rotationAxis[CiX] = 0.0;
    rotationAxis[CiY] = 1.0;
    rotationAxis[CiZ] = 0.0;
    rotationAxis[CiW] = 1.0;
    
    quaternionInitialize(offsetYQuaternion, rotationAxis, offsetY);
    
    // set up for offsetZ
    // -------------------------------------
    rotationAxis[CiX] = 0.0;
    rotationAxis[CiY] = 0.0;
    rotationAxis[CiZ] = 1.0;
    rotationAxis[CiW] = 1.0;
    
    switch(self.orientation)
    {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
        {
            // must use the portraitOrientationHFOVRadians value here!!!
            HFOV = self.portraitOrientationHFOVRadians;
            
            // no basic offset for Z when in portrait, however
            // there is the custom offset
            offsetZ = 0 + self.customHeadingOffsetRadians;
            
            // pull the quaternion from CoreMotion
            // NOTE: these values are tweaked/shuffled so as to counteract the
            //       tension created by holding the device in the desired
            //       neutral orientation as compared to the true neutral
            //       orientation (which is the device laying down on a table
            //       w/ the back side of the device facing downward)
            // --------------------------------------------------------------------
            finalQuaternion[QiW] = self.quaternion.w;
            finalQuaternion[QiX] = -self.quaternion.z;
            finalQuaternion[QiY] = -self.quaternion.x;
            finalQuaternion[QiZ] = self.quaternion.y;
            
            break;
        }
        case UIInterfaceOrientationLandscapeRight:
        {
            // can use landscapeOrientationHFOVRadians as-is
            HFOV = self.landscapeOrientationHFOVRadians;
            
            // needs custom offsetZ that is unique to LandscapeRight
            offsetZ = -PIOver2 + self.customHeadingOffsetRadians;
            
            // pull the quaternion from CoreMotion
            // NOTE: these values are tweaked/shuffled so as to counteract the
            //       tension created by holding the device in the desired
            //       neutral orientation as compared to the true neutral
            //       orientation (which is the device laying down on a table
            //       w/ the back side of the device facing downward)
            // --------------------------------------------------------------------
            finalQuaternion[QiW] = self.quaternion.w;
            finalQuaternion[QiX] = -self.quaternion.z;
            finalQuaternion[QiY] = self.quaternion.y;
            finalQuaternion[QiZ] = self.quaternion.x;
            
            break;
        }
        case UIInterfaceOrientationLandscapeLeft:
        {
            // can use landscapeOrientationHFOVRadians as-is
            HFOV = self.landscapeOrientationHFOVRadians;
            
            // needs custom offsetZ that is unique to LandscapeLeft
            offsetZ = PIOver2 + self.customHeadingOffsetRadians;
            
            // pull the quaternion from CoreMotion
            // NOTE: these values are tweaked/shuffled so as to counteract the
            //       tension created by holding the device in the desired
            //       neutral orientation as compared to the true neutral
            //       orientation (which is the device laying down on a table
            //       w/ the back side of the device facing downward)
            // --------------------------------------------------------------------
            finalQuaternion[QiW] = self.quaternion.w;
            finalQuaternion[QiX] = -self.quaternion.z;
            finalQuaternion[QiY] = -self.quaternion.y;
            finalQuaternion[QiZ] = -self.quaternion.x;
            
            break;
        }
        default:
        {
            break;
        }
    }
    
    // Create offsetZQuaternion, and then apply the Y and Z quaternions up to
    // the point of having a finalQuaternion, which is then used to the
    // create the rotation matrix
    // --------------------------------------------------------------------
    quaternionInitialize(offsetZQuaternion, rotationAxis, offsetZ);
    quaternionMultiply(offsetZQuaternion, offsetYQuaternion);
    quaternionMultiply(offsetYQuaternion, finalQuaternion);
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
    
    if(_isPlaying == NO)
    {
        [self setNeedsDisplay];
    }
}

-(MTLSize)threadsPerGroup {
    return MTLSizeMake(8, 8, 1);
}

-(MTLSize)threadGroups {
    MTLSize groupCount = [self threadsPerGroup];
    return MTLSizeMake((((NSUInteger)self.bounds.size.width) / groupCount.width), (((NSUInteger)self.bounds.size.height) / groupCount.height), 1);
}

-(float)portraitOrientationHFOVRadians {
    // must derive HFOV from landscapeFOV and widths and heights.
    // ----------------------------------------------------------
    float HFOV = 0;
    float dstWidth = self.drawableSize.width;
    float dstHeight = self.drawableSize.height;
    
    switch(self.orientation)
    {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
        {
            //  - dstWidth here is the width of the portrait-oriented dst img
            //  - dstHeight here is the width of the landscape-oriented dst img
            HFOV = 2.0 * atan2((0.5 * dstWidth), ((0.5 * dstHeight) / tan(0.5 * self.landscapeOrientationHFOVRadians)));
            break;
        }
        case UIInterfaceOrientationLandscapeRight:
        case UIInterfaceOrientationLandscapeLeft:
        {
            //  - dstHeight here is the width of the portrait-oriented dst img
            //  - dstWidth here is the width of the landscape-oriented dst img
            HFOV = 2.0 * atan2((0.5 * dstHeight), ((0.5 * dstWidth) / tan(0.5 * self.landscapeOrientationHFOVRadians)));
            break;
        }
        default:
        {
            break;
        }
    }
    
    return HFOV;
}

-(float)currentHFOVRadians {
    // returns landscape HFOV if in landscape mode,
    // returns portrait HFOV if in portrait mode
    float HFOV = self.landscapeOrientationHFOVRadians;
    
    switch(self.orientation)
    {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
        {
            HFOV = self.portraitOrientationHFOVRadians;
            break;
        }
        default:
        {
            break;
        }
    }
    
    return HFOV;
}

@end

