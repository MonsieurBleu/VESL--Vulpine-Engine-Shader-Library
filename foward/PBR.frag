#version 460

#include SceneDefines3D.glsl

#define USING_VERTEX_TEXTURE_UV
#define SKYBOX_REFLECTION
// #define CUBEMAP_SKYBOX

#ifdef ARB_BINDLESS_TEXTURE
#extension GL_ARB_bindless_texture : require
#endif

#include uniform/Base3D.glsl
#include uniform/Model3D.glsl

#ifdef ARB_BINDLESS_TEXTURE
layout (location = 20, bindless_sampler) uniform sampler2D bColor;
layout (location = 21, bindless_sampler) uniform sampler2D bMaterial;
#else
layout(binding = 0) uniform sampler2D bColor;
layout(binding = 1) uniform sampler2D bMaterial;
#endif

#include globals/Fragment3DInputs.glsl
#include globals/Fragment3DOutputs.glsl

#include functions/MultiLight.glsl
#include functions/Reflections.glsl
#include functions/NormalMap.glsl

// #define USING_LOD_TESSELATION
// layout(binding = 2) uniform sampler2D bHeight;

void main()
{
    vec4 CE = texture(bColor, uv);
    vec4 NRM = texture(bMaterial, uv);

    if(NRM.x <= 0.01 && NRM.y <= 0.01)
        discard;

#ifndef USING_LOD_TESSELATION
    mEmmisive = 1.0 - CE.a;
    normalComposed = normal;
#else
    mEmmisive = 0.0;


    normalComposed = normal;
    // float nbias = 0.01;
    // float dist = nbias;

    // float nh1 = texture(bHeight, clamp(uv, 0.001, 0.999)).r;
    // vec3 nP1 = normal*nh1; 
    
    // float nh2 = texture(bHeight, clamp(uv+vec2(0, nbias), 0.001, 0.999)).r - 0.5;
    // float nh3 = texture(bHeight, clamp(uv+vec2(nbias, 0), 0.001, 0.999)).r - 0.5;
    // vec3 nP2 = normal*nh2 + vec3(0.0, 0.0, dist); 
    // vec3 nP3 = normal*nh3 + vec3(dist, 0.0, 0.0); 

    // float nh4 = texture(bHeight, clamp(uv-vec2(0, nbias), 0.001, 0.999)).r - 0.5;
    // float nh5 = texture(bHeight, clamp(uv-vec2(nbias, 0), 0.001, 0.999)).r - 0.5; 
    // vec3 nP4 = normal*nh4 - vec3(0.0, 0.0, dist); 
    // vec3 nP5 = normal*nh5 - vec3(dist, 0.0, 0.0); 

    // vec3 n1 = normalize(cross(nP2-nP1, nP3-nP1));
    // vec3 n2 = normalize(cross(nP4-nP1, nP5-nP1));

    // normalComposed = normalize(n2+n1);

#endif
    mMetallic = 1.0 - NRM.a;
    mRoughness = NRM.b;
    mRoughness2 = mRoughness * mRoughness;
    color = CE.rgb;
    normalComposed = perturbNormal(normalComposed, viewVector, NRM.xy, uv);
    viewDir = normalize(_cameraPosition - position);

    normalComposed = gl_FrontFacing ? normalComposed : -normalComposed;

    Material material = getMultiLight();
    vec3 rColor = getSkyboxReflection(viewDir, normalComposed);
    const float reflectFactor = getReflectionFactor(1.0 - nDotV, mMetallic, mRoughness);
    fragColor.rgb = color * ambientLight + material.result + rColor * reflectFactor;

    fragColor.rgb = mix(fragColor.rgb, color, mEmmisive);
    fragEmmisive = getStandardEmmisive(fragColor.rgb);

    // fragNormal = normalize((vec4(normalComposed, 0.0) * _cameraInverseViewMatrix).rgb)*0.5 + 0.5;
    fragNormal = normalize((vec4(normalComposed, 0.0) * inverse(_cameraViewMatrix)).rgb) * 0.5 + 0.5;

    // fragColor.rgb = normal;
    // fragColor.rgb = vec3(1);
}
