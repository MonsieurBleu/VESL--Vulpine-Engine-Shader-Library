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

vec3 getClosestLightHit(sampler2DArray shadowmap, mat4 rMatrix, vec3 pos)
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
    float d = texture(shadowmap, vec3(samplePos * .5 + .5, 0)).r;

    vec4 shadowPos = vec4(mapPosition.xy, d, 1.0);

    shadowPos = inverse(rMatrix) * shadowPos;
    // shadowPos /= shadowPos.w;

    return shadowPos.xyz;
}

#define EFFICIENT_SMOOTH_SHADOW
float getShadow(sampler2DArray shadowmap, mat4 rMatrix, float nDotL)
{
    vec4 mapPosition = rMatrix * vec4(lcalcPosition, 1.0);
    mapPosition.xyz /= mapPosition.w;
    mapPosition.xy = mapPosition.xy * 0.5 + 0.5;

    const float borderBias = 1e-3;

    if (mapPosition.x < borderBias || mapPosition.x > 1.0-borderBias ||
        mapPosition.y < borderBias || mapPosition.y > 1.0-borderBias)
        {
            color = vec3(2, 0, 0);
            // return 1.;
        }

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
            float d = texture(shadowmap, vec3(samplePos, 0)).r;
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
                float d = texture(shadowmap, vec3(samplePos, 0)).r;
                res += d - bias < mapPosition.z ? 1.0 : 0.0;
            }
        }

        res /= float(i);
    #else
        res = texture(shadowmap, vec3(mapPosition.xy, 0)).r - bias < mapPosition.z ? 1.0 : 0.0;
    #endif
    // res = 0.0;
    return res;
}

float getShadowMapHit(in out float dist, sampler2DArray shadowmap,vec3 mapPosition, int layer, float bias, float randRadius, vec2 it, float randSeed)
{
    vec2 samplePos = mapPosition.xy + randRadius * normalize((0.5-vulpineHash2to2(it.xx, randSeed)));
    float d = texture(shadowmap, vec3(samplePos, layer)).r;
    dist = max(dist, abs(d-mapPosition.z));
    return d - bias < mapPosition.z ? 1.0 : 0.0;
}

float getCascadedShadow(sampler2DArray shadowmap, mat4 matrix[3], float nDotL)
{
    float res = 0.0;

    for(int l = 0; l < LIGHT_LAYERS; l++)
    {
        vec4 mapPosition = matrix[l] * vec4(lcalcPosition, 1.0);
        mapPosition.xyz /= mapPosition.w;
        mapPosition.xy = mapPosition.xy * 0.5 + 0.5;

        const float borderBias = 1e-2;
        
        if (
                mapPosition.x < borderBias || mapPosition.x > 1.0-borderBias ||
                mapPosition.y < borderBias || mapPosition.y > 1.0-borderBias ||
                mapPosition.z < 0.0        || mapPosition.z > 1.0
            )
            {
                // color = vec3(2, 0, 0);

                continue;
            }
    
        float bias = 1e-5 * (1.0 + float(l)*5.0 - (1.0-abs(nDotL*8.0)));
        bias = clamp(bias, 0.0, 1.0);
        float randRadius = ESS_BASE_PENUMBRA_RADIUS / (1.0 + 1.0*pow(2.0, float(l)));

        float dist = 0.001;

        const float maxDistPenubraFactor = 32.0;

        for(int i = 0; i < ESS_BASE_ITERATION; i++)
        {
            // float currentRandRadius = randRadius * (1.0 + min(dist*512.0, 128.0));
            float currentRandRadius = randRadius*maxDistPenubraFactor;
            vec2 ruv = vec2(0.5);
            res += getShadowMapHit(dist, shadowmap, mapPosition.xyz, l, bias, currentRandRadius, ruv, float(i));
        }

        res /= ESS_BASE_ITERATION;

        if(distance(res, 0.5) >= 0.4)
        {
            // color[2] = 300; 
            // return res;
        }
        else
            res = 0.0;

        // dist = 0.01;
        dist = smoothstep(0.001, 0.1, dist);
        float currentRandRadius = randRadius * (1.0 + min(dist*256.0*maxDistPenubraFactor, maxDistPenubraFactor-1));
        // currentRandRadius = randRadius*16.0;


        // color[0] = currentRandRadius*256.0;
        // color[0] = currentRandRadius/randRadius;

        // float currentRandRadius = randRadius * (1.0 + min(dist*2048, 16.0));
        for(int i = 0; i < ESS_PENUMBRA_ITERATION; i++)
        {
            
            // float currentRandRadius = randRadius*16.0;
            // vec2 ruv = mapPosition.zz - mod(mapPosition.zz, vec2(0.00001));
            vec2 ruv = mapPosition.xy;
            ruv = vec2(0.5);
            res += getShadowMapHit(dist, shadowmap, mapPosition.xyz, l, bias, currentRandRadius, ruv, float(-i));
        }


        // res -= 64;
        // res += 64;
        res /= ESS_PENUMBRA_ITERATION;
        res = smoothstep(0.0, 1.0, res);    
        return res;
    }

    return 1.0;
}


void getLightDirectionnal(
    inout Material lightResult, 
    inout float factor,
    in vec3 direction, 
    in vec3 color, 
    in float intensity, 
    in bool shadows,
    in int mapID,
    in mat4 matrix[3])
{
    if(intensity <= 1e-3) return;

    float sss = 0.;

    #ifdef SUBSURFACE_SCATTERING
    float sssStep = 5.0;
    if(!shadows)
    for(float i = 0; i < sssStep; i++)
    {
        vec3 ssspos = lcalcPosition - 0.02*(vulpineHash2to3(vec2(1.), i)*2. - 1.);
        vec3 SSSpos = getClosestLightHit(bShadowMaps[mapID], matrix[0], ssspos);
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
    // factor = shadows ? intensity : intensity*getShadow(bShadowMaps[mapID], matrix[0], dot(normalComposed, direction));
    factor = shadows ? intensity : intensity*getCascadedShadow(bShadowMaps[mapID], matrix, dot(normalComposed, direction));


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

    for(int i = 0; i < 1; i++)
    {
        // i = 0;
        Light sun = lights[i];
        getLightDirectionnal(
            r, factor, sun.direction.xyz, lSunColor, sun.color.a, 
            (sun.infos.b % 2) == 0, sun.infos.r, sun.matrix);
        result.result += r.result*factor;
        result.reflected += r.reflected;
        result.specular += r.specular*factor;
    }


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