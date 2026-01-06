#ifndef FNCT_NOISE_GLSL
#define FNCT_NOISE_GLSL

#include Hash 

/*****
    INSPIRED BY GOLD NOISE

    Kiiinda slow and not seedable noise function.
    Made for the legacy VESL noise library
*****/
float rand2to1(vec2 p)
{
    return
        fract(sin(distance(sign(p)+p*0.3*(0.25+PHI*1e-5), vec2(PHI*1e-5, PI*1e-5)))*SQR2*10000.0);
}

float rand3to1(vec3 p)
{
    return
        fract(sin(distance(sign(p.xyz)+p.xyz*0.3*(0.25+PHI*1e-5), vec3(PHI*1e-5, PI*1e-5, E)))*SQR2*10000.0);
}

vec2 rand3to2(vec3 p)
{
    return vec2(
        fract(sin(distance(sign(p.xyz)+p.xyz*0.3*(0.25+PHI*1e-5), vec3(PHI*1e-5, PI*1e-5, E)))*SQR2*10000.0),
        fract(sin(distance(sign(p.yzx)+p.yzx*0.5*(0.32+PHI*1e-5), vec3(PHI*1e-5, PI*1e-5, E)))*SQR2*10000.0)
    );
}

vec3 rand3to3(vec3 p)
{
    return vec3(
        fract(sin(distance(sign(p.xyz)+p.xyz*0.3*(0.25+PHI*1e-5), vec3(PHI*1e-5, PI*1e-5, E)))*SQR2*10000.0),
        fract(sin(distance(sign(p.yzx)+p.yzx*0.5*(0.32+PHI*1e-5), vec3(PHI*1e-5, PI*1e-5, E)))*SQR2*10000.0),
        fract(sin(distance(sign(p.zxy)+p.zxy*0.2*(0.21+PHI*1e-5), vec3(PHI*1e-5, PI*1e-5, E)))*SQR2*10000.0)
    );
}





// https://www.shadertoy.com/view/wtsSW4
float gold_noise3(in vec3 coordinate, in float seed){
    return 0.5 - fract(tan(distance(coordinate*(seed+PHI*00000.1), vec3(PHI*00000.1, PI*00000.1, E)))*SQR2*10000.0);
}

vec2 goldNoiseCustom(in vec3 coordinate, in float seed)
{
    return vec2(0.5) - vec2(2.0)*vec2(
        fract(tan(distance(coordinate.xy*PHI, coordinate.xy)*seed)*coordinate.x),
        fract(tan(distance(coordinate.zx*PHI, coordinate.zx)*seed)*coordinate.z)
        );
}

vec3 goldNoise3to3(in vec3 coordinate, in float seed)
{
    return vec3(
        fract(tan(0.859*distance(coordinate.xy*PHI, coordinate.xz)*seed)*coordinate.y),
        fract(tan(1.589*distance(coordinate.yz*PHI, coordinate.zx)*seed)*coordinate.z),
        fract(tan(2.099*distance(coordinate.zy*PHI, coordinate.yz)*seed)*coordinate.x)
        );
}

// https://github.com/tt6746690/computer-graphics-shader-pipeline/blob/master/src/random2 
vec2 random2(vec3 st){
  vec2 S = vec2( dot(st,vec3(127.1,311.7,783.089)),
             dot(st,vec3(269.5,183.3,173.542)) );
  return fract(sin(S)*43758.5453123);
}

vec2 random2(vec2 st){
    st = vec2( dot(st,vec2(127.1,311.7)),
              dot(st,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(st)*43758.5453123);
}

float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))
                 * 43758.5453123);
}

// Gradient gradientNoise by Inigo Quilez - iq/2013
// https://www.shadertoy.com/view/XdXGW8
float gradientNoise(vec2 st) {

    vec2 i = floor(st);
    vec2 f = fract(st);

    vec2 u = f*f*(3.0-2.0*f);

    return (mix( mix( dot( random2(i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ),
                     dot( random2(i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( random2(i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ),
                     dot( random2(i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y)) * .5 + .5;
}





// https://github.com/MaxBittker/glsl-voronoi-noise
    const mat2 vor3d_myt = mat2(.12121212, .13131313, -.13131313, .12121212);
    const vec2 vor3d_mys = vec2(1e4, 1e6);

    vec2 vor3d_rhash(vec2 uv)
    {
        uv *= vor3d_myt;
        uv *= vor3d_mys;
        return fract(fract(uv / vor3d_mys) * uv);
    }

    // vec3 vor3d_hash(vec3 p)
    // {
    //     return fract(
    //         sin(vec3(dot(p, vec3(1.0, 57.0, 113.0)), dot(p, vec3(57.0, 113.0, 1.0)),
    //                 dot(p, vec3(113.0, 1.0, 57.0)))) *
    //         43758.5453);
    // }

    vec3 vor3d_hash(vec3 p)
    {
        return vec3(
            fract(sin(distance(sign(p.xyz)+p.xyz*0.3*(0.25+PHI*1e-5), vec3(PHI*1e-5, PI*1e-5, E)))*SQR2*10000.0),
            fract(sin(distance(sign(p.yzx)+p.yzx*0.5*(0.32+PHI*1e-5), vec3(PHI*1e-5, PI*1e-5, E)))*SQR2*10000.0),
            fract(sin(distance(sign(p.zxy)+p.zxy*0.2*(0.21+PHI*1e-5), vec3(PHI*1e-5, PI*1e-5, E)))*SQR2*10000.0)
        );
    }


    vec3 voronoi3d(const in vec3 x, inout vec3 cell_center)
    {
        vec3 p = floor(x);
        vec3 f = fract(x);

        cell_center = vec3(0);

        float id = 0.0;
        vec2 res = vec2(100.0);
        for (int k = -1; k <= 1; k++) {
            for (int j = -1; j <= 1; j++) {
                for (int i = -1; i <= 1; i++) {
                    vec3 b = vec3(float(i), float(j), float(k));
                    vec3 r = vec3(b) - f + vor3d_hash(p + b);
                    float d = dot(r, r);

                    float cond = max(sign(res.x - d), 0.0);
                    float nCond = 1.0 - cond;

                    float cond2 = nCond * max(sign(res.y - d), 0.0);
                    float nCond2 = 1.0 - cond2;

                    id = (dot(p + b, vec3(1.0, 57.0, 113.0)) * cond) + (id * nCond);
                    res = vec2(d, res.x) * cond + res * nCond;

                    res.y = cond2 * d + nCond2 * res.y;

                    cell_center = (p + b) * cond + cell_center * nCond;
                }
            }
        }

        return vec3(sqrt(res), vor3d_rhash(vec2(id)));
    }




//
// Description : Array and textureless GLSL 2D simplex noise function.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : ijm
//     Lastmod : 20110822 (ijm)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
//

vec3 mod289(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
  return mod289(((x*34.0)+1.0)*x);
}

float snoise(vec2 v)
  {
  const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                      0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                     -0.577350269189626,  // -1.0 + 2.0 * C.x
                      0.024390243902439); // 1.0 / 41.0
// First corner
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);

// Other corners
  vec2 i1;
  //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
  //i1.y = 1.0 - i1.x;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  // x0 = x0 - 0.0 + 0.0 * C.xx ;
  // x1 = x0 - i1 + 1.0 * C.xx ;
  // x2 = x0 - 1.0 + 2.0 * C.xx ;
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;

// Permutations
  i = mod289(i); // Avoid truncation effects in permutation
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
    + i.x + vec3(0.0, i1.x, 1.0 ));

  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;

// Gradients: 41 points uniformly over a line, mapped onto a diamond.
// The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;

// Normalise gradients implicitly by scaling m
// Approximation of: m *= inversesqrt( a0*a0 + h*h );
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

// Compute final noise value at P
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}

//
// GLSL textureless classic 2D noise "cnoise",
// with an RSL-style periodic variant "pnoise".
// Author:  Stefan Gustavson (stefan.gustavson@liu.se)
// Version: 2011-08-22
//
// Many thanks to Ian McEwan of Ashima Arts for the
// ideas for permutation and gradient selection.
//
// Copyright (c) 2011 Stefan Gustavson. All rights reserved.
// Distributed under the MIT license. See LICENSE file.
// https://github.com/ashima/webgl-noise
//

vec4 mod289(vec4 x)
{
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x)
{
  return mod289(((x*34.0)+1.0)*x);
}

vec4 taylorInvSqrt(vec4 r)
{
  return 1.79284291400159 - 0.85373472095314 * r;
}

vec2 fade(vec2 t) {
  return t*t*t*(t*(t*6.0-15.0)+10.0);
}

// Classic Perlin noise
float cnoise(vec2 P)
{
  vec4 Pi = floor(P.xyxy) + vec4(0.0, 0.0, 1.0, 1.0);
  vec4 Pf = fract(P.xyxy) - vec4(0.0, 0.0, 1.0, 1.0);
  Pi = mod289(Pi); // To avoid truncation effects in permutation
  vec4 ix = Pi.xzxz;
  vec4 iy = Pi.yyww;
  vec4 fx = Pf.xzxz;
  vec4 fy = Pf.yyww;

  vec4 i = permute(permute(ix) + iy);

  vec4 gx = fract(i * (1.0 / 41.0)) * 2.0 - 1.0 ;
  vec4 gy = abs(gx) - 0.5 ;
  vec4 tx = floor(gx + 0.5);
  gx = gx - tx;

  vec2 g00 = vec2(gx.x,gy.x);
  vec2 g10 = vec2(gx.y,gy.y);
  vec2 g01 = vec2(gx.z,gy.z);
  vec2 g11 = vec2(gx.w,gy.w);

  vec4 norm = taylorInvSqrt(vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11)));
  g00 *= norm.x;
  g01 *= norm.y;
  g10 *= norm.z;
  g11 *= norm.w;

  float n00 = dot(g00, vec2(fx.x, fy.x));
  float n10 = dot(g10, vec2(fx.y, fy.y));
  float n01 = dot(g01, vec2(fx.z, fy.z));
  float n11 = dot(g11, vec2(fx.w, fy.w));

  vec2 fade_xy = fade(Pf.xy);
  vec2 n_x = mix(vec2(n00, n01), vec2(n10, n11), fade_xy.x);
  float n_xy = mix(n_x.x, n_x.y, fade_xy.y);
  return 2.3 * n_xy;
}


//	Simplex 3D Noise 
//	by Ian McEwan, Stefan Gustavson (https://github.com/stegu/webgl-noise)
//
// vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
// vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}

float snoise(vec3 v){ 
  const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
  const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

// First corner
  vec3 i  = floor(v + dot(v, C.yyy) );
  vec3 x0 =   v - i + dot(i, C.xxx) ;

// Other corners
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min( g.xyz, l.zxy );
  vec3 i2 = max( g.xyz, l.zxy );

  //  x0 = x0 - 0. + 0.0 * C 
  vec3 x1 = x0 - i1 + 1.0 * C.xxx;
  vec3 x2 = x0 - i2 + 2.0 * C.xxx;
  vec3 x3 = x0 - 1. + 3.0 * C.xxx;

// Permutations
  i = mod(i, 289.0 ); 
  vec4 p = permute( permute( permute( 
             i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
           + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

// Gradients
// ( N*N points uniformly over a square, mapped onto an octahedron.)
  float n_ = 1.0/7.0; // N=7
  vec3  ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z *ns.z);  //  mod(p,N*N)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );

  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  vec3 p0 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1.xy,h.z);
  vec3 p3 = vec3(a1.zw,h.w);

//Normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

// Mix final noise value
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), 
                                dot(p2,x2), dot(p3,x3) ) );
}


#endif
