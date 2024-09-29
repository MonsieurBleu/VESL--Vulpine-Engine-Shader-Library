#ifndef FNCT_REFLECTIONS_GLSL
#define FNCT_REFLECTIONS_GLSL

#include functions/Skybox.glsl

float getReflectionFactor(float fresnel, float metallic, float roughness)
{
    const float maxReflectivity = 0.5;
    const float metallicExponent = 1.75*(1.0 - metallic*0.5);
    const float roughnessFactor = (1.0-sqrt(roughness));
    const float reflectFactor = roughnessFactor*min(maxReflectivity, pow(fresnel, metallicExponent));
    return reflectFactor;
}

vec3 getSkyboxReflection(vec3 v, vec3 n)
{
    #ifdef SKYBOX_REFLECTION
        vec3 reflectDir = normalize(reflect(v, n));
        #ifdef CUBEMAP_SKYBOX
            reflectColor = texture(bSkyTexture, -reflectDir).rgb;
        #else

            vec2 uvSky = vec2(
                0.5 + atan(reflectDir.z, -reflectDir.x)/(2.0*PI), 
                reflectDir.y*0.5 + 0.5
            );

            vec3 r = vec3(0);

            for(int i = 0; i < 4; i++)
            {
                vec2 uvSky2 = uvSky;
                /*
                    Fast roughness reflection blur
                */
                const float noiseMaxDist = 0.05;

                #ifdef USING_VERTEX_TEXTURE_UV
                vec3 noiseUv = vec3(uv, 1.0);
                #else
                vec3 noiseUv = modelPosition;
                #endif

                uvSky2 += (1.0 - 2.0*random2(noiseUv + i))*noiseMaxDist*mRoughness;
                uvSky2.y = clamp(uvSky2.y, 0.f, 0.999);

                r += getSkyColor(uvSky); 
            }

            return r/4.0; 
        #endif
    #else
        return vec3(0.f);
    #endif
}

#endif
