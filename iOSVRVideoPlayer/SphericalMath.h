//
//  SphericalMath.h
//  iOSVRVideoPlayer
//
//  Created by Joshua Bodinet on 4/28/18.
//  Copyright © 2018 JoshuaBodinet. All rights reserved.
//

#ifndef SphericalMath_h
#define SphericalMath_h

#include <stdbool.h>

#define PI_RAW (3.1415926535897932384626433832795028841971)

const float PI = PI_RAW;
const float PI2 = PI_RAW * 2.0f;
const float PIOver2 = PI_RAW * 0.5;

const float RadToDeg = (float) ( 180.0 / PI_RAW );
const float DegToRad = (float) ( PI_RAW / 180.0 );

void quaternionInitialize(float local [4], float axis [4], float angleRad);
void quaternionMultiply(float local [4], float total [4]);
void quaternionToMatrix(float quaternion [4], float matrix [16]);
void matrixMultiply(float matrix [16], float vector [4], bool scaleToWEquals1 /*= true*/);
void vectorNormalize(float vector [4]);
void quaternionNormalize(float vector [4]);

enum QuaternionIndex { QiW = 0, QiX, QiY, QiZ };
enum CartesianIndex { CiX = 0, CiY, CiZ, CiW };


#endif /* SphericalMath_h */
