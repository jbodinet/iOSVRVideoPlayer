//
//  MetalParam.hpp
//  MetalTextureTest
//
//  Created by Joshua Bodinet on 2/11/17.
//  Copyright © 2017 StereoDynamicImaging. All rights reserved.
//

#ifndef MetalParam_h
#define MetalParam_h

#endif /* MetalParam_h */

typedef struct
{
    float rotationMatrix [16];
    
    float dstToEquirectPixDensity;
    float halfHFOV;
    float halfVFOV;
    float halfHFOV_tangent;
    float radius;
    
    unsigned equirectWidth;
    unsigned equirectHeight;
} MetalParam;

