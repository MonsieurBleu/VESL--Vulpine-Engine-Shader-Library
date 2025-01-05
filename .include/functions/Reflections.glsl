#ifndef FNCT_REFLECTIONS_GLSL
#define FNCT_REFLECTIONS_GLSL

#include functions/Skybox.glsl

float getReflectionFactor(float fresnel, float metallic, float roughness)
{
    // const float maxReflectivity = 1.;
    // const float metallicExponent = 1.5*(1.0 - metallic*0.5);
    // const float roughnessFactor = (1.0-sqrt(roughness));
    // const float reflectFactor = roughnessFactor*min(maxReflectivity, pow(fresnel, metallicExponent));

    // // return clamp(reflectFactor, 0., 1.);

    // return reflectFactor;

    const float iroughness = 1.0 - roughness;
    const float roughnessFactor = iroughness*iroughness*(1.0 - metallic);
    const float metallicFactor = metallic;

    const float reflectFactor = roughnessFactor + metallicFactor;

    return reflectFactor;
}

vec3 getSkyboxReflection(vec3 v, vec3 n)
{
    #ifdef SKYBOX_REFLECTION
        vec3 reflectDir = normalize(reflect(v, n));
        #ifdef CUBEMAP_SKYBOX
            reflectColor = texture(bSkyTexture, -reflectDir).rgb;
        #else

            // vec2 uvSky = vec2(
            //     0.5 + atan(reflectDir.z, -reflectDir.x)/(2.0*PI), 
            //     reflectDir.y*0.5 + 0.5
            // );

            // vec3 r = vec3(0);

            // for(int i = 0; i < 4; i++)
            // {
            //     vec2 uvSky2 = uvSky;
            //     /*
            //         Fast roughness reflection blur
            //     */
            //     const float noiseMaxDist = 0.05;

            //     #ifdef USING_VERTEX_TEXTURE_UV
            //     vec3 noiseUv = vec3(uv, 1.0);
            //     #else
            //     vec3 noiseUv = modelPosition;
            //     #endif

            //     uvSky2 += (1.0 - 2.0*random2(noiseUv + i))*noiseMaxDist*mRoughness;
            //     uvSky2.y = clamp(uvSky2.y, 0.f, 0.999);

            //     r += getSkyColor(uvSky); 
            // }
            // return r/4.0; 

            // vec3 c = clamp(getSkyColor(-reflectDir), vec3(0), vec3(1));
            
            vec3 tmp;
            vec3 voronoi = voronoi3d(reflectDir * 10., tmp);
            reflectDir = mix(reflectDir, normalize(rand3to3(tmp) * 2.0 - 1.0), 0.3*mRoughness);
            // reflectDir = mix(reflectDir, normalize(rand3to3(reflectDir) * 2.0 - 1.0), 0.1*mRoughness);
            reflectDir = normalize(reflectDir);

            
            vec3 c = clamp(getAtmopshereColor(-reflectDir), vec3(0), vec3(1));

            vec3 c2 = getAmbientInteriorColor(-reflectDir)*0.5;

            

            // c2 = vec3(0.25, 0.2, 0.1)*0.5;
            // sunLightMult = 0;

            vec3 finalReflection = mix(max(c, c2), c2, 1. - pow(sunLightMult, 0.5));

            // finalReflection = finalReflection * (0.5 + 0.5*(1.0 - mRoughness));

            return finalReflection;


        #endif
    #else
        return vec3(0.f);
    #endif
}

#endif
