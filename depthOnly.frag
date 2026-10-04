#version 460

#include SceneDefines3D 
// #define USING_VERTEX_TEXTURE_UV


#include Base3D 
#include Model3D 
#include Ligths 

#ifdef WATER
#include Noise
// in vec3 position;
// in vec3 modelPosition;

layout (binding = 4) uniform sampler2D bFlow;
#include Water

#endif

// #ifdef ARB_BINDLESS_TEXTURE
// layout (location = 20, bindless_sampler) uniform sampler2D bColor;
// layout (location = 21, bindless_sampler) uniform sampler2D bMaterial;
// #else
// layout(binding = 0) uniform sampler2D bColor;
// layout(binding = 1) uniform sampler2D bMaterial;
// #endif


#include Fragment3DInputs 
#include Fragment3DOutputs 

#include standardMaterial 

#ifdef USING_VERTEX_PACKING
    in vec3 modelPosition;
    in vec3 modelNormal;
#endif

// #ifdef LEAF
//     #ifdef ARB_BINDLESS_TEXTURE
//         layout (location = 20, bindless_sampler) uniform sampler2D bLeaf;
//     #else
//         layout(binding = 0) uniform sampler2D bLeaf;
//     #endif

//     in vec2 uv;
// #endif

// #ifdef LEAF_PATCH
//     in vec3 normal;
// #endif

void main()
{
    #ifdef WATER
    // discard;
    // ivec2 iuv = ivec2(gl_FragCoord);

    // float n = snoise(position.xz*2.0 + _iTime);

    // // if(iuv.x%16 != 0) discard;

    // if(n > 0.0) discard;

    float h = waveHeight(position.xz, (position.xz+2048.0)/4096.0, 100.0);
    
    // if(mod(h, 0.25) < 0.125) discard;

    if(sin(h*12.0) > h) discard;

    #endif

    #ifdef LEAF_PATCH
        // vec3 normalCs = normalize(cross(dFdx(position), dFdy(position)));

        float d = length(normal);
        // color.r = length(normal)*0.1;

        // d = pow(d, 5000.0);
        if(d >= 0.7)
        {
            // if(int(gl_FragCoord.x)%2 == 0)
                discard;
        }

        // normalComposed = normalCs;
    #endif

    return;
    // #ifdef LEAF_ALPHA
    // if(texture(bLeaf, clamp(uv, vec2(0), vec2(1))).r < 1e-6) discard;
    // #endif
}
