#version 460

#include SceneDefines3D 
// #define USING_VERTEX_TEXTURE_UV


#include Base3D 
#include Model3D 
#include Ligths 

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

void main()
{
    return;
    // #ifdef LEAF_ALPHA
    // if(texture(bLeaf, clamp(uv, vec2(0), vec2(1))).r < 1e-6) discard;
    // #endif
}
