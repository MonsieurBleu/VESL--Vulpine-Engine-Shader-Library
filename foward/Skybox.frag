#version 460

#include SceneDefines3D.glsl

#ifdef ARB_BINDLESS_TEXTURE
#extension GL_ARB_bindless_texture : require
#endif

#define USING_VERTEX_TEXTURE_UV

#include uniform/Base3D.glsl
#include uniform/Model3D.glsl
#include uniform/Ligths.glsl

#ifdef ARB_BINDLESS_TEXTURE
layout (location = 20, bindless_sampler) uniform sampler2D bTexture;
#else
layout (binding = 0) uniform sampler2D bTexture;
#endif



#include globals/Fragment3DInputs.glsl
#include globals/Fragment3DOutputs.glsl

#include functions/standardMaterial.glsl
#include functions/Noise.glsl
#include functions/Skybox.glsl

in vec3 viewPos;





void main()
{
    getSkyColors(normalize(position), fragColor.rgb, fragEmmisive.rgb);

    fragColor.a = 1.0;

    fragNormal = vec3(1);
}
