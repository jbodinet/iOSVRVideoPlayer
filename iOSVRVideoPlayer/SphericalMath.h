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

#ifndef SphericalMath_h
#define SphericalMath_h

#include <stdbool.h>

#define PI_RAW (3.1415926535897932384626433832795028841971)

extern const float PI;
extern const float PI2;
extern const float PIOver2;

extern const float RadToDeg;
extern const float DegToRad;

void quaternionInitialize(float local [4], float axis [4], float angleRad);
void quaternionMultiply(float local [4], float total [4]);
void quaternionToMatrix(float quaternion [4], float matrix [16]);
void matrixMultiply(float matrix [16], float vector [4], bool scaleToWEquals1 /*= true*/);
void vectorNormalize(float vector [4]);
void quaternionNormalize(float vector [4]);

enum QuaternionIndex { QiW = 0, QiX, QiY, QiZ };
enum CartesianIndex { CiX = 0, CiY, CiZ, CiW };


#endif /* SphericalMath_h */
