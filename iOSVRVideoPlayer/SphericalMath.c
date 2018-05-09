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

#include <math.h>
#include "SphericalMath.h"

const float PI = PI_RAW;
const float PI2 = PI_RAW * 2.0f;
const float PIOver2 = PI_RAW * 0.5;

const float RadToDeg = ((float) ( 180.0 / PI_RAW ));
const float DegToRad = ((float) ( PI_RAW / 180.0 ));

void quaternionInitialize(float local [4], float axis [4], float angleRad)
{
    /*
     // Local rotation formula
     //
     //note: axis is a unit vector and is the axis about which rotation will occur
     local_rotation.w  = cosf( fAngle/2)
     local_rotation.x = axis.x * sinf( fAngle/2 )
     local_rotation.y = axis.y * sinf( fAngle/2 )
     local_rotation.z = axis.z * sinf( fAngle/2 )
     */
    
    local[QiW] = cos(angleRad / 2.0f);
    local[QiX] = axis[CiX] * sin(angleRad / 2.0f);
    local[QiY] = axis[CiY] * sin(angleRad / 2.0f);
    local[QiZ] = axis[CiZ] * sin(angleRad / 2.0f);
}

void quaternionMultiply(float local [4], float total [4])
{
    /*
     // Quaternion multiplication (NOT COMMUTATIVE!!!)
     // note: here Q1 is 'local' and Q2 is 'total'
     (Q1 * Q2).w = (w1w2 - x1x2 - y1y2 - z1z2)
     (Q1 * Q2).x = (w1x2 + x1w2 + y1z2 - z1y2)
     (Q1 * Q2).y = (w1y2 - x1z2 + y1w2 + z1x2)
     (Q1 * Q2).z = (w1z2 + x1y2 - y1x2 + z1w2)
     */
    
    float tempTotal [4];
    // memcpy(tempTotal, total, sizeof(float) * 4);
    tempTotal[0] = total[0];
    tempTotal[1] = total[1];
    tempTotal[2] = total[2];
    tempTotal[3] = total[3];
    
    total[QiW] = ((local[QiW] * tempTotal[QiW]) - (local[QiX] * tempTotal[QiX]) - (local[QiY] * tempTotal[QiY]) - (local[QiZ] * tempTotal[QiZ]));
    total[QiX] = ((local[QiW] * tempTotal[QiX]) + (local[QiX] * tempTotal[QiW]) + (local[QiY] * tempTotal[QiZ]) - (local[QiZ] * tempTotal[QiY]));
    total[QiY] = ((local[QiW] * tempTotal[QiY]) - (local[QiX] * tempTotal[QiZ]) + (local[QiY] * tempTotal[QiW]) + (local[QiZ] * tempTotal[QiX]));
    total[QiZ] = ((local[QiW] * tempTotal[QiZ]) + (local[QiX] * tempTotal[QiY]) - (local[QiY] * tempTotal[QiX]) + (local[QiZ] * tempTotal[QiW]));
}

void quaternionToMatrix(float quaternion [4], float matrix [16])
{
    // note: to convert handedness, transpose the matrix, which is easy. Due to how the factors
    //       of the matrix line up, you just have to switch the sign of the elements not on the
    //       main diagonal
    
    // total form of matrix
    /*
     w^2+x^2-y^2-z^2        2xy-2wz             2xz+2wy             0
     
     2xy+2wz                w^2-x^2+y^2-z^2     2yz-2wx             0
     
     2xz-2wy                2yz+2wx             w^2-x^2-y^2+z^2     0
     
     0                      0                   0                   1
     */
    
    // due to the fact that we are dealing w/ unit quaternions, this can reduce down to:
    /*
     1-2y^2-2z^2        2xy-2wz         2xz+2wy         0
     
     2xy+2wz            1-2x^2-2z^2     2yz-2wx         0
     
     2xz-2wy            2yz+2wx         1-2x^2-2y^2     0
     
     0                  0               0               1
     */
    
    // row major indexing
    
    // row 0
    matrix[0 ] = 1 - (2 * (quaternion[QiY] * quaternion[QiY])) - (2 * (quaternion[QiZ] * quaternion[QiZ]));
    matrix[1 ] = (2 * quaternion[QiX] * quaternion[QiY]) - (2 * quaternion[QiW] * quaternion[QiZ]);
    matrix[2 ] = (2 * quaternion[QiX] * quaternion[QiZ]) + (2 * quaternion[QiW] * quaternion[QiY]);
    matrix[3 ] = 0;
    
    // row 1
    matrix[4 ] = (2 * quaternion[QiX] * quaternion[QiY]) + (2 * quaternion[QiW] * quaternion[QiZ]);
    matrix[5 ] = 1 - (2 * quaternion[QiX] * quaternion[QiX]) - (2 * quaternion[QiZ] * quaternion[QiZ]);
    matrix[6 ] = (2 * quaternion[QiY] * quaternion[QiZ]) - (2 * quaternion[QiW] * quaternion[QiX]);
    matrix[7 ] = 0;
    
    // row 2
    matrix[8 ] = (2 * quaternion[QiX] * quaternion[QiZ]) - (2 * quaternion[QiW] * quaternion[QiY]);
    matrix[9 ] = (2 * quaternion[QiY] * quaternion[QiZ]) + (2 * quaternion[QiW] * quaternion[QiX]);
    matrix[10] = 1 - (2 * quaternion[QiX] * quaternion[QiX]) - (2 * quaternion[QiY] * quaternion[QiY]);
    matrix[11] = 0;
    
    // row 3
    matrix[12] = 0;
    matrix[13] = 0;
    matrix[14] = 0;
    matrix[15] = 1;
}

void matrixMultiply(float matrix [16], float vector [4], bool scaleToWEquals1)
{
    float tempVector [4];
    // std::memcpy(tempVector, vector, sizeof(float) * 4);
    tempVector[0] = vector[0];
    tempVector[1] = vector[1];
    tempVector[2] = vector[2];
    tempVector[3] = vector[3];
    
    // row major multiplication
    vector[CiX] = (matrix[0 ] * tempVector[CiX]) + (matrix[1 ] * tempVector[CiY]) + (matrix[2 ] * tempVector[CiZ]) + (matrix[3 ] * tempVector[CiW]);
    vector[CiY] = (matrix[4 ] * tempVector[CiX]) + (matrix[5 ] * tempVector[CiY]) + (matrix[6 ] * tempVector[CiZ]) + (matrix[7 ] * tempVector[CiW]);
    vector[CiZ] = (matrix[8 ] * tempVector[CiX]) + (matrix[9 ] * tempVector[CiY]) + (matrix[10] * tempVector[CiZ]) + (matrix[11] * tempVector[CiW]);
    vector[CiW] = (matrix[12] * tempVector[CiX]) + (matrix[13] * tempVector[CiY]) + (matrix[14] * tempVector[CiZ]) + (matrix[15] * tempVector[CiW]);
    
    if(scaleToWEquals1 && vector[CiW] != 1.0)
    {
        vector[CiX] /= vector[CiW];
        vector[CiY] /= vector[CiW];
        vector[CiZ] /= vector[CiW];
        vector[CiW] = 1.0;
    }
}

void vectorNormalize(float vector [4])
{
    float magnitude = sqrt((vector[CiX] * vector[CiX]) + (vector[CiY] * vector[CiY]) + (vector[CiZ] * vector[CiZ]));
    
    vector[CiX] /= magnitude;
    vector[CiY] /= magnitude;
    vector[CiZ] /= magnitude;
    vector[CiW] /= 1.0;
}

void quaternionNormalize(float vector [4])
{
    float magnitude = sqrt((vector[QiW] * vector[QiW]) + (vector[QiX] * vector[QiX]) + (vector[QiY] * vector[QiY]) + (vector[QiZ] * vector[QiZ]));
    
    vector[QiW] /= magnitude;
    vector[QiX] /= magnitude;
    vector[QiY] /= magnitude;
    vector[QiZ] /= magnitude;
}
