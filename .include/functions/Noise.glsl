#ifndef FNCT_NOISE_GLSL
#define FNCT_NOISE_GLSL

#include globals/Constants.glsl


/*****
    ACTUAL GOOD AND SOMEWHAT FAST RANDOM FUNCTIONS INSPIRED BY GOLD NOISE

    seed can be easly implemented
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

// https://github.com/tt6746690/computer-graphics-shader-pipeline/blob/master/src/random2.glsl
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



#endif
