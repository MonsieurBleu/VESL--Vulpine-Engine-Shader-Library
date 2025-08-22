#version 460

#include SceneDefines3D 

#define USING_VERTEX_TEXTURE_UV
#define SKYBOX_REFLECTION
// #define CUBEMAP_SKYBOX

#ifdef ARB_BINDLESS_TEXTURE
#extension GL_ARB_bindless_texture : require
#endif

 #include Base3D 
 #include Model3D 
 #include Ligths 

#ifdef ARB_BINDLESS_TEXTURE
layout (location = 20, bindless_sampler) uniform sampler2D bColor;
layout (location = 21, bindless_sampler) uniform sampler2D bMaterial;
#else
layout(binding = 0) uniform sampler2D bColor;
layout(binding = 1) uniform sampler2D bMaterial;
#endif

 #include Fragment3DInputs 
 #include Fragment3DOutputs 

#include Noise 
#include HSV

ivec3 getClusterId(const float ivFar, const ivec3 steps)
{
    vec3 id = gl_FragCoord.rgb;
    id.rg /= vec2(_iResolution);
    id.b = ivFar/id.b;

    return ivec3(floor(id*vec3(steps)));
}

void main()
{
    const float vFar = 5e3;
    const ivec3 steps = ivec3(16, 9, 1);

    ivec3 cluster = getClusterId(1.0/vFar, steps);

    if(cluster.b < steps.b)
        fragColor.rgb = hsv2rgb(vec3(gold_noise3(cluster, 0), 1.0, 1.0));
    else 
        fragColor.rgb = vec3(0.85);

    fragEmmisive = vec3(0);

    fragNormal = normalize((vec4(normal, 0.0) * inverse(_cameraViewMatrix)).rgb) * 0.5 + 0.5;
}
