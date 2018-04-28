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
        self.drawableSize = CGSizeMake(1920, 1080); // *** IS THIS CORRECT FOR WHAT WE WANT?
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
    
    // create the params buffer
    MetalParam metalParam = self.metalParam;
    id<MTLBuffer> paramsBuffer = [self.device newBufferWithBytes:&(metalParam) length:sizeof(metalParam) options:MTLResourceOptionCPUCacheModeDefault];
    
    // set the input texture, the output texture, and the params buffer
    [commandEncoder setTexture:srcTexture atIndex:0]; // SRC TEXTURE
    [commandEncoder setTexture:drawable.texture atIndex:1];
    [commandEncoder setBuffer:paramsBuffer offset:0 atIndex:0];
    
    // Convert the time in a metal buffer.
    float time = (float)self.inputTime;
    [commandEncoder setBytes:&time length:sizeof(float) atIndex:0];
    
    // encode a threadgroup's execution of a compute function
    [commandEncoder dispatchThreadgroups:[self threadGroups] threadsPerThreadgroup:[self threadGroupCount]];
    
    // end the encoding of the command.
    [commandEncoder endEncoding];
    
    // Register the current drawable for rendering.
    [commandBuffer presentDrawable:drawable];
    
    // Commit the command buffer for execution.
    [commandBuffer commit];
}

-(MTLSize)threadGroupCount {
    return MTLSizeMake(8, 8, 1);
}

-(MTLSize)threadGroups {
    MTLSize groupCount = [self threadGroupCount];
    return MTLSizeMake((((NSUInteger)self.bounds.size.width) / groupCount.width), (((NSUInteger)self.bounds.size.height) / groupCount.height), 1);
}

@end

