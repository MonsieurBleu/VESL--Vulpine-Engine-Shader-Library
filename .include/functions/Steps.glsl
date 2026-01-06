#ifndef STEPS_GLSL
#define STEPS_GLSL

float csmoothstep(float e, float x)
{
    x /= e;
    return .5 + x*(.75 - .25*x*x);
}

float usmoothstep(float edge0, float edge1, float x)
{
    float t; 
    t = (x - edge0) / (edge1 - edge0);
    return t * t * (3.0 - 2.0 * t);
}

float linearstep(float e0, float e1, float x)
{
    return clamp((x - e0)/(e1 - e0), 0., 1.);
}

vec3 linearstep(vec3 e0, vec3 e1, vec3 x)
{
    return clamp((x - e0)/(e1 - e0), 0., 1.);
}

float cubicstep(float edge0, float edge1, float x)
{
    float t = (x - edge0) / (edge1 - edge0) - .5;
    return clamp(t*t*t*4. + .5, 0., 1.);
}

float invsmoothstep(float edge0, float edge1, float x)
{
    return .5 + sin(asin(1 - 2.*linearstep(edge1, edge0, x))/3.);
}

#endif