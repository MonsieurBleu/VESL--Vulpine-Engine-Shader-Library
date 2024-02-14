#include uniform/Ligths.glsl

#include functions/Noise.glsl
#include functions/standardMaterial.glsl


/*
    Efficient soft-shadow with percentage-closer filtering
    link : https://developer.nvidia.com/gpugems/gpugems2/part-ii-shading-lighting-and-shadows/chapter-17-efficient-soft-edged-shadows-using
*/
// #define EFFICIENT_SMOOTH_SHADOW
float getShadow(sampler2D shadowmap, mat4 rMatrix, float nDotL)
{
    vec4 mapPosition = rMatrix * vec4(position, 1.0);
    mapPosition.xyz /= mapPosition.w;
    mapPosition.xy = mapPosition.xy * 0.5 + 0.5;

    if (mapPosition.x < 0. || mapPosition.x > 1. ||
        mapPosition.y < 0. || mapPosition.y > 1.)
        return 1.;

    float res = 0.;
    float bias = 0.00005; // 0.00002
    // bias /= 1.0 + nDotL;
    float radius = 0.001; // 0.0015

    #ifdef EFFICIENT_SMOOTH_SHADOW
        int it = 8;
        int itPenumbra = 64;
        int i = 0;

        for (; i < it; i++)
        {
            vec2 rand = vec2(gold_noise3(position, i), gold_noise3(position, -i));
            // vec2 rand = 0.5 - random2(position+i);
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
                vec2 rand = vec2(gold_noise3(position, i), gold_noise3(position, -i));
                // vec2 rand = 0.5 - random2(position+i);
                vec2 samplePos = mapPosition.xy + radius * rand;
                float d = texture(shadowmap, samplePos).r;
                res += d - bias < mapPosition.z ? 1.0 : 0.0;
            }
        }

        res /= float(i);
    #else
        res = texture(shadowmap, mapPosition.xy).r - bias < mapPosition.z ? 1.0 : 0.0;
    #endif

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
    lightResult = getLighting(direction, color);
    factor = shadows ? intensity : intensity*getShadow(bShadowMaps[mapID], matrix, dot(normalComposed, direction));
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
    float distFactor = max(maxDist - distance(position, lPosition), 0.) / maxDist;
    factor = distFactor * distFactor * intensity;
    lightResult = getLighting(normalize(position - lPosition), color);
}

/*
    TODO : add tube light
*/

#ifdef USE_CLUSTERED_RENDERING
ivec3 getClusterId(const float ivFar, const ivec3 steps)
{
    vec3 id = gl_FragCoord.rgb;
    id.rg /= vec2(_iResolution);
    id.b = ivFar/id.b;

    return ivec3(floor(id*vec3(steps)));
}

Material getMultiLight()
{
    Material result; result.result = vec3(.0);
    nDotV = max(dot(normalComposed, viewDir), .0);

    const ivec3 frustumClusterDim = ivec3(16, 9, 24);
    ivec3 clusterId = getClusterId(1.f/5e3, frustumClusterDim);

    if(clusterId.z > frustumClusterDim.z) return result;

    int id = 
    clusterId.x*frustumClusterDim.y*frustumClusterDim.z
    + clusterId.y*frustumClusterDim.z
    + clusterId.z;

    id *= 128;

    int lid = 0;

    for(;; id++)
    {
        int lid = lightsID[id];

        Light l = lights[lid];
        Material r; r.result = vec3(.0);
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
    }

    return result;
}

#else
Material getMultiLight()
{
    int id = 0;
    Material result; result.result = vec3(.0);
    nDotV = max(dot(normalComposed, viewDir), .0);

    for(;;id++)
    {
        Light l = lights[id];
        Material r; r.result = vec3(.0);
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
    }

    return result;
}

#endif