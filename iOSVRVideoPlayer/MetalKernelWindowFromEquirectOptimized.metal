//
//  MetalKernel.metal
//  MetalTextureTest
//
//  Created by Joshua Bodinet on 2/7/17.
//  Copyright © 2017 StereoDynamicImaging. All rights reserved.
//

#include <metal_stdlib>
#include <metal_math>
using namespace metal;
using namespace metal::precise;

#include "MetalParamWindowFromEquirectOptimized.h"

// constant float PI = metal::precise::atan(1.0f) * 4; // you get really cryptic errors if you use this method of defining PI
constant float PI = 3.1415926535897932384626433832795028841971;
constant float PI2 = PI * 2.0f;

float fixPolarRange(float value, float naturalPolarRange);


enum QuaternionIndex { QiW = 0, QiX, QiY, QiZ };
enum CartesianIndex { CiX = 0, CiY, CiZ, CiW };

kernel void kernelFunctionEquirectangularToRectilinear(texture2d<float, access::read> inTexture [[texture(0)]],
                                                       texture2d<float, access::write> outTexture [[texture(1)]],
                                                       uint2 gid [[thread_position_in_grid]],
                                                       constant MetalParam* params [[ buffer(0) ]])
{
    float halfDstWidth = 0.5 * outTexture.get_width();
    float equirectWidth = inTexture.get_width();
    float equirectHeight = inTexture.get_height();
    
    float srcTheta = 0;
    float srcPhi = 0;
    
    float vecSrc [3], vecDst [3];
    
//    if(true)
//    {
//        float4 colorAtPixel = float4(gid.x / (float)equirectWidth, 0.0, 0.0, 1.0);
//        outTexture.write(colorAtPixel, gid);
//        return;
//    }
    
    vecSrc[CiX] = (halfDstWidth * params->dstToEquirectPixDensity) / params->halfHFOV_tangent;
    vecSrc[CiY] = ((params->halfHFOV / PI2) * equirectWidth) - (gid.x * params->dstToEquirectPixDensity);
    vecSrc[CiZ] = ((params->halfVFOV / PI) * equirectHeight) - (gid.y * params->dstToEquirectPixDensity);
    
    vecDst[CiX] = (params->rotationMatrix[0 ] * vecSrc[CiX]) + (params->rotationMatrix[1 ] * vecSrc[CiY]) + (params->rotationMatrix[2 ] * vecSrc[CiZ]);
    vecDst[CiY] = (params->rotationMatrix[4 ] * vecSrc[CiX]) + (params->rotationMatrix[5 ] * vecSrc[CiY]) + (params->rotationMatrix[6 ] * vecSrc[CiZ]);
    vecDst[CiZ] = (params->rotationMatrix[8 ] * vecSrc[CiX]) + (params->rotationMatrix[9 ] * vecSrc[CiY]) + (params->rotationMatrix[10] * vecSrc[CiZ]);
    
    float magnitude = metal::precise::sqrt(vecDst[CiX]*vecDst[CiX] + vecDst[CiY]*vecDst[CiY] + vecDst[CiZ]*vecDst[CiZ]);
    vecDst[CiX] *= (params->radius/magnitude);
    vecDst[CiY] *= (params->radius/magnitude);
    vecDst[CiZ] *= (params->radius/magnitude);
    
    srcPhi = metal::precise::acos( vecDst[CiZ] / params->radius );
    srcTheta = metal::precise::acos( vecDst[CiX] / ( params->radius * metal::precise::sin(srcPhi)));
    
    if(vecDst[CiY] < 0)
    {
        srcTheta = PI2 - srcTheta;
    }
    
    srcTheta = fixPolarRange(srcTheta, PI2);
    srcPhi = fixPolarRange(srcPhi, PI);
    
    srcTheta = PI2 - srcTheta;
    
    uint32_t equirectPixCol = (srcTheta / PI2) * equirectWidth;
    uint32_t equirectPixRow = (srcPhi / PI) * equirectHeight;
    
    // go through the pixels and just shade them for now
    if(equirectPixCol < equirectWidth && equirectPixRow < equirectHeight)
    {
        outTexture.write(inTexture.read(uint2(equirectPixCol, equirectPixRow)), gid);
    }
    
    return;
}

float fixPolarRange(float value, float naturalPolarRange)
{
    if(value < 0)
    {
        float scalar = PI / (-value);
        value += (uint32_t(scalar + 0.5) * naturalPolarRange);
    }
    
    return metal::precise::fmod(value, naturalPolarRange);
}



