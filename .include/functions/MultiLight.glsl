#include Ligths 

#include Noise 
#include standardMaterial 

vec3 lcalcPosition = vec3(0.0);
vec3 lSunColor = vec3(1);

/*
    Efficient soft-shadow with percentage-closer filtering
    link : https://developer.nvidia.com/gpugems/gpugems2/part-ii-shading-lighting-and-shadows/chapter-17-efficient-soft-edged-shadows-using
*/
#ifndef ESS_BASE_ITERATION
#define ESS_BASE_ITERATION 8
#endif

#ifndef ESS_PENUMBRA_ITERATION
#define ESS_PENUMBRA_ITERATION 64
#endif

#ifndef ESS_BASE_PENUMBRA_RADIUS
#define ESS_BASE_PENUMBRA_RADIUS 0.001
#endif

vec3 getClosestLightHit(sampler2D shadowmap, mat4 rMatrix, vec3 pos)
{
    vec4 mapPosition = rMatrix * vec4(pos, 1.0);
    mapPosition.xyz /= mapPosition.w;
    // mapPosition.xy = mapPosition.xy * 0.5 + 0.5;

    const float borderBias = 1e-3;

    if (mapPosition.x < -1.0-borderBias || mapPosition.x > 1.0-borderBias ||
        mapPosition.y < -1.0-borderBias || mapPosition.y > 1.0-borderBias)
        return pos;

    float res = 0.;
    float bias = 0.00005;

    vec2 samplePos = mapPosition.xy;
    float d = texture(shadowmap, samplePos * .5 + .5).r;

    vec4 shadowPos = vec4(mapPosition.xy, d, 1.0);

    shadowPos = inverse(rMatrix) * shadowPos;
    // shadowPos /= shadowPos.w;

    return shadowPos.xyz;
}

#define EFFICIENT_SMOOTH_SHADOW
float getShadow(sampler2D shadowmap, mat4 rMatrix, float nDotL)
{
    vec4 mapPosition = rMatrix * vec4(lcalcPosition, 1.0);
    mapPosition.xyz /= mapPosition.w;
    mapPosition.xy = mapPosition.xy * 0.5 + 0.5;

    const float borderBias = 1e-3;

    if (mapPosition.x < borderBias || mapPosition.x > 1.0-borderBias ||
        mapPosition.y < borderBias || mapPosition.y > 1.0-borderBias)
        return 1.;

    float res = 0.;
    float bias = 0.000025

        // * (1.0 - distance(nDotL, cos(PI*0.5)))

        // * (0.1 + 0.9*pow(max((nDotL), 0.0), 1.0))
        // * clamp(abs(nDotL - 0.5)*2.0, 0., 1.)
    ; // 0.00002

    // fragColor.rgb = vec3(1.0 - nDotL);
    // return 1.0 - distance(nDotL, cos(PI*0.5));

    // sunLightMult = bias;

    // bias /= 1.0 + nDotL;
    float radius = ESS_BASE_PENUMBRA_RADIUS; // 0.0015

    vec3 scalcPosition = lcalcPosition - mod(lcalcPosition, vec3(0.0001));
    // scalcPosition = lcalcPosition;
    scalcPosition = vec3(1);

    #ifdef EFFICIENT_SMOOTH_SHADOW
        int it = ESS_BASE_ITERATION;
        int itPenumbra = ESS_PENUMBRA_ITERATION;
        int i = 0;

        for (; i < it; i++)
        {
            // vec2 rand = vec2(gold_noise3(lcalcPosition, i), gold_noise3(lcalcPosition, -i));
            // vec2 rand = 0.5 - random2(position+i);
            vec2 rand = vulpineHash3to2(scalcPosition, i)*2. - 1.;
            rand = normalize(rand);
            vec2 samplePos = mapPosition.xy + 2.0 * radius * rand;
            float d = texture(shadowmap, samplePos).r;
            res += d - bias < mapPosition.z ? 1.0 : 0.0;
        }

        float p = float(it) * 0.5;
        float prct = abs(res - p) / p;

        if (prct < 1.)
        {
            // float p = float(it)*0.5;
            // float prct = 0.5 + 0.5*abs(res-p)/p;
            // itPenumbra = int(float(itPenumbra)*prct);

            for (; i < itPenumbra; i++)
            {
                // vec2 rand = vec2(gold_noise3(lcalcPosition, i), gold_noise3(lcalcPosition, -i));
                // vec2 rand = 0.5 - random2(position+i);
                vec2 rand = vulpineHash3to2(scalcPosition, i)*2. - 1.;
                rand = normalize(rand);
                vec2 samplePos = mapPosition.xy + radius * rand;
                float d = texture(shadowmap, samplePos).r;
                res += d - bias < mapPosition.z ? 1.0 : 0.0;
            }
        }

        res /= float(i);
    #else
        res = texture(shadowmap, mapPosition.xy).r - bias < mapPosition.z ? 1.0 : 0.0;
    #endif
    // res = 0.0;
    return res;
}

void getLightDirectionnal(
    inout Material lightResult, 
    inout float factor,
    in vec3 direction, 
    in vec3 color, 
    in float intensity, 
    in bool shadows,
    in int mapID,
    in mat4 matrix)
{
    if(intensity <= 1e-3) return;

    float sss = 0.;

    #ifdef SUBSURFACE_SCATTERING
    float sssStep = 5.0;
    if(!shadows)
    for(float i = 0; i < sssStep; i++)
    {
        vec3 ssspos = lcalcPosition - 0.02*(vulpineHash2to3(vec2(1.), i)*2. - 1.);
        vec3 SSSpos = getClosestLightHit(bShadowMaps[mapID], matrix, ssspos);
        float SSSt = dot(-(SSSpos-lcalcPosition), direction);
        SSSt = max(SSSt, 0.);

        float radius = 0.05;
        SSSt /= radius;
        sss += clamp(exp(-SSSt), 0., 1.);
    }
    sss /= sssStep;
    sss *= 0.5 + 0.5*(1.0-mMetallic);
    sss *= mSubSurfaceScattering;
    #endif

    lightResult = getLighting(direction, color, sss);
    factor = shadows ? intensity : intensity*getShadow(bShadowMaps[mapID], matrix, dot(normalComposed, direction));

    // sunLightMult = max(dot(-direction, normalComposed), 0);
    // sunLightMult += factor;

    sunLightMult = min(factor, max(dot(-direction, normalComposed) + 1.0, 0));

    // sunLightMult = factor;

    // sunLightMult = min(sunLightMult , 1.0);


    // lightResult.result = sss.xxx;
    // factor = 1.0;
}

void getLightPoint(
    inout Material lightResult, 
    inout float factor,
    in float radius, 
    in vec3 lPosition,
    in vec3 color, 
    in float intensity)
{
    float maxDist = max(radius, 0.0001);
    float distFactor = max(maxDist - distance(lcalcPosition, lPosition), 0.) / maxDist;
    factor = distFactor * distFactor * intensity;
    lightResult = getLighting(normalize(lcalcPosition - lPosition), color);
}

/*
    TODO : add tube light
*/

#define GET_LIGHT_INIT \
    Material result; result.result = vec3(.0); result.reflected = vec3(0.); result.specular = vec3(0.); \
    nDotV = max(dot(normalComposed, viewDir), 1e-6);


#ifdef USE_CLUSTERED_RENDERING
ivec3 getClusterId(const float ivFar, const ivec3 steps)
{
    vec3 id = gl_FragCoord.rgb;
    id.rg /= vec2(_iResolution);
    id.b = ivFar / id.b;

    return ivec3(floor(id*vec3(steps)));
}

float cnttmptmp = 0.f;

Material getMultiLight()
{
    GET_LIGHT_INIT

    float factor = 0.f;
    Material r;
    r.result = vec3(.0);
    r.reflected = vec3(.0);
    Light sun = lights[0];
    getLightDirectionnal(
        r, factor, sun.direction.xyz, lSunColor, sun.color.a, 
        (sun.infos.b % 2) == 0, sun.infos.r, sun.matrix);
    result.result += r.result*factor;
    result.reflected += r.reflected;
    result.specular += r.specular*factor;
    // sunLightMult += length(r.result)*factor;

    // Light moon = lights[1];
    // getLightDirectionnal(
    //     r, factor, moon.direction.xyz, moon.color.rgb, moon.color.a, 
    //     (moon.infos.b % 2) == 0, moon.infos.r, moon.matrix);
    // result.result += r.result*factor*factor;
    // result.reflected += r.reflected;
    // result.specular += r.specular;

    ivec3 clusterId = getClusterId(vFarLighting, frustumClusterDim);

    if(clusterId.z >= frustumClusterDim.z) return result;
    if(clusterId.x >= frustumClusterDim.x) return result;
    if(clusterId.y >= frustumClusterDim.y) return result;
    if(clusterId.z < 0) return result;
    if(clusterId.x < 0) return result;
    if(clusterId.y < 0) return result;

    int id = 
    clusterId.x*frustumClusterDim.y*frustumClusterDim.z
    + clusterId.y*frustumClusterDim.z
    + clusterId.z;

    id *= 128;

    int lid = 0;
    
    for(;; id++)
    {
        int lid = lightsID[id];
        cnttmptmp += 1.;

        Light l = lights[lid];
        r.result = vec3(.0);
        factor = 0.f;

        switch(l.infos.a)
        {
            case 0 : return result; break;
            
            case 2 : 
                getLightPoint(r, factor, l.direction.x, l.position.xyz, l.color.rgb, l.color.a);
            break;
            default : break;
        }

        result.result += r.result*factor;
        result.reflected += r.reflected;
        result.specular += r.specular*factor;
    }

    return result;
}

#else
Material getMultiLight()
{
    int id = 0;

    GET_LIGHT_INIT 

    for(;;id++)
    {
        Light l = lights[id];
        Material r; r.result = vec3(.0); r.reflected = vec3(0.0); r.specular = vec3(0.);
        float factor = 0.f;

        switch(l.infos.a)
        {
            case 0 : return result;
            case 1 : 
                getLightDirectionnal(
                    r, factor, l.direction.xyz, l.color.rgb, l.color.a, 
                    (l.infos.b % 2) == 0, l.infos.r, l.matrix);
            break;
            case 2 : 
                getLightPoint(r, factor, l.direction.x, l.position.xyz, l.color.rgb, l.color.a);
            break;
            default : break;
        }

        result.result += r.result*factor;
        result.reflected += r.reflected;
        result.specular += r.specular*factor;
    }

    return result;
}

#endif