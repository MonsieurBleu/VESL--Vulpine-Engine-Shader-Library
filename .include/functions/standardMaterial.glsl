#include HSV
 #include Constants 

float mRoughness = 0.0;
float mRoughness2 = 0.0;
float mMetallic = 0.0;
float mEmmisive = 0.0;

float sunLightMult = 0.0;

// vec3 ambientLight = vec3(0.2);
vec3 normalComposed = vec3(0.0);
vec3 viewDir = vec3(0.0);
vec3 color = vec3(0.0);
float nDotV = 0.0;

struct Material
{
    vec3 result;
    vec3 reflected;
};

#ifdef USE_PBR
Material getLighting(vec3 lightDirection, vec3 lightColor)
{
    vec3 F0 = mix(vec3(0.04), color, mMetallic);

    vec3 halfwayDir = normalize(-lightDirection + viewDir);
    float nDotH = max(dot(normalComposed, halfwayDir), 0.0);
    float nDotL = max(dot(normalComposed, -lightDirection), 0.0);

    #ifdef USE_TOON_SHADING
        // float tmp3 = 0.01;
        // nDotL = smoothstep(tmp3, tmp3+0.01, nDotL);

        // float tmp3 = 0.1; nDotL *= smoothstep(tmp3, tmp3+0.1, nDotL);

        // float tmp3 = 0.0; nDotL = smoothstep(tmp3, tmp3+0.5, nDotL);

        // float tmp4 = (1.0-mRoughness);
        // float tmp4 = 0.5;
        // nDotH= smoothstep(tmp4, tmp4+0.01, nDotH);

        // float tmp5 = 0.0;
        // nDotV = smoothstep(tmp5, 0.85, nDotV);
    #endif

    float nDotH2 = nDotH * nDotH;

    vec3 fresnelSchlick = F0 + (1.0 - F0) * pow(1.0 - nDotH, 5.0);

    float nDenom = (nDotH2 * (mRoughness2 - 1.0) + 1.0);
    float normalDistrib = mRoughness2 / (PI * nDenom * nDenom);

    float gK = mRoughness2 * 0.5;
    float gKi = 1.0 - gK;
    float geometry = (nDotL * nDotV) / ((nDotV * gKi + gK) * (nDotL * gKi + gK));

    vec3 specular = fresnelSchlick * normalDistrib * geometry / max((4.0 * nDotV * nDotL), 0.00000001);

    vec3 kD = (vec3(1.0) - fresnelSchlick) * (1.0 - mMetallic);
    vec3 diffuse = kD * color / PI;
    
    
    Material result;
    result.reflected = fresnelSchlick;
    result.reflected = vec3(.0);
    #ifdef USE_TOON_SHADING
        // float tmp1 = (1-mRoughness)*0.25 
        //     *pow(fresnelSchlick.x, 0.5)
        //     ;
        // specular *= smoothstep(tmp1, tmp1+0.001, specular);

        // lightColor *= 2 .0; 
        
        // diffuse = step(vec3(0.1), diffuse);

        // specular += specular*vec3(nDotH2);

        result.result = (specular + diffuse) * lightColor * nDotL * 2.;
    #else

        // specular = vec3(0);
        // diffuse = vec3(0);



        result.result = (specular + diffuse) * lightColor * nDotL * 2.;
    #endif

    return result;
}
#else
#ifdef USE_BLINN_PHONG
Material getLighting(vec3 lightDirection, vec3 lightColor)
{
    float diffuseIntensity = 1.0;
    float specularIntensity = 2.0 + mMetallic*5.0;
    float fresnelIntensity = 0.5 + 2.0*mMetallic;

    float nDotL = max(dot(-lightDirection, normalComposed), 0.0);
    vec3 halfwayDir = normalize(-lightDirection+viewDir);

    float diffuse = nDotL*diffuseIntensity;
    specularIntensity *= diffuse;
    fresnelIntensity *= diffuse;

    float specularExponent = 36.0 - 32.0*pow(mRoughness, 0.5);
    float specular = specularIntensity*pow(max(dot(normal, halfwayDir), 0.0), specularExponent);
    
    float fresnel = fresnelIntensity*pow((1.0 - dot(normal, viewDir)), 4.0);

    Material result;
    result.result = lightColor*(diffuse+specular+fresnel);
    return result;
}
#else
Material getLighting(vec3 lightDirection, vec3 lightColor)
{
    Material result;
    result.result = lightColor;
    return result;
}
#endif
#endif


/*
Material getMultiLightPBR()
{
    int id = 0;
    Material result;

    nDotV = max(dot(normalComposed, viewDir), 0.0);
    result.fresnel = 1.0 - nDotV;
    result.result = vec3(0);

    while (true)
    {
        Light light = lights[id];
        Material lightResult = {
            vec3(0.), 0.};
        float factor = 1.0;
        switch (light.stencil.a)
        {
        case 0:
            return result;
            break;

        case 1:
            lightResult = getBRDF(light.direction.xyz, light.color.rgb);
            factor = light.color.a;
            factor *= (light.stencil.b % 2) == 0 ? 1. : getShadow(bShadowMaps[light.stencil.r], light._rShadowMatrix);
            break;

        case 2:
        {
            float maxDist = max(light.direction.x, 0.0001);
            float distFactor = max(maxDist - distance(position, light.position.xyz), 0.) / maxDist;
            vec3 direction = normalize(position - light.position.xyz);

            lightResult = getBRDF(direction, light.color.rgb);
            factor = distFactor * distFactor * light.color.a;
        }
        break;

        case 3:
        {
            vec3 pos1 = light.position.xyz;
            vec3 pos2 = light.direction.xyz;
            vec3 H = position - pos1;
            vec3 tubeDir = normalize(pos1 - pos2);
            float cosinus = dot(normalize(H), tubeDir);
            float A = cosinus * length(H);
            vec3 sPos = pos1 + tubeDir * A;

            float segL = length(pos1 - pos2);
            sPos = mix(sPos, pos1, step(segL, length(sPos - pos2)));
            sPos = mix(sPos, pos2, step(segL, length(sPos - pos1)));

            float radius = 5.0;

            //
            //    TODO : fix radius
            //
            float maxDist = max(light.direction.a, 0.0001);
            float distFactor = max(maxDist - distance(sPos, position), 0.) / maxDist;
            vec3 direction = normalize(position - sPos);

            lightResult = getBRDF(direction, light.color.rgb);
            factor = distFactor * distFactor * light.color.a;
        }
        break;

        default:
            break;
        }

        result.result += lightResult.result * factor;

        id++;
    }

    return result;
}
*/

vec3 getStandardEmmisive(vec3 fcolor)
{
    // vec3 baseEmmissive = fcolor*(rgb2v(fcolor) - ambientLight*0.5);
    // vec3 finalEmmisive = mix(baseEmmissive, 2.0*fcolor, mEmmisive);

    // vec3 baseEmmissive = fcolor*pow(rgb2v(fcolor), 2.0);

    // vec3 baseEmmissive = pow(fcolor, vec3(1.5));

    float im = 1.0-mMetallic;
    // vec3 baseEmmissive = pow(fcolor, vec3(2.0) + rgb2v(fcolor)*20.f*(0.03 + im));
    // baseEmmissive *= 0.025*(0.01 + im);

    float lum = rgb2v(fcolor);
    float eFactor = 0.01 * (0.001 + im);
    float eExponent = 2.0 + lum*1.0;
    // eFactor += mMetallic * 0.5;
    vec3 baseEmmissive = pow(fcolor, vec3(eExponent)) * eFactor;



    // vec3 finalEmmisive = baseEmmissive * (1.0 + 2.0 * mEmmisive);
    // vec3 finalEmmisive = baseEmmissive * (1.0 + (mEmmisive * 1));
    vec3 finalEmmisive = vec3(mEmmisive) * color * 0.1;

    finalEmmisive = mix(baseEmmissive, finalEmmisive, mEmmisive);

    return finalEmmisive;
}