#version 460

#include SceneDefines3D.glsl

#ifdef ARB_BINDLESS_TEXTURE
#extension GL_ARB_bindless_texture : require
#endif

#include uniform/Base3D.glsl
#include uniform/Model3D.glsl
#include uniform/Ligths.glsl

layout (location = 20, bindless_sampler) uniform vec3 bColor;

#ifdef ARB_BINDLESS_TEXTURE
layout (location = 20, bindless_sampler) uniform sampler2D bColor;
layout (location = 21, bindless_sampler) uniform sampler2D bMaterial;
#else
layout(binding = 0) uniform sampler2D bColor;
layout(binding = 1) uniform sampler2D bMaterial;
#endif

#include globals/Fragment3DInputs.glsl
#include globals/Fragment3DOutputs.glsl

#include functions/standardMaterial.glsl

void main()
{
    normalComposed = normal;
    normalComposed = gl_FrontFacing ? normalComposed : -normalComposed;

    fragColor.rgb = bColor;
    fragEmmisive = getStandardEmmisive(fragColor.rgb);

    fragNormal = normalize((vec4(normalComposed, 0.0) * inverse(_cameraViewMatrix)).rgb) * 0.5 + 0.5;
}
