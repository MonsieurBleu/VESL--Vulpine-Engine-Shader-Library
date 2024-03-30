#version 460

#include SceneDefines3D.glsl
#define USING_VERTEX_TEXTURE_UV

#include SceneDefines3D.glsl

#include uniform/Base3D.glsl
#include uniform/Model3D.glsl
#include uniform/Ligths.glsl

layout (location = 20) uniform vec3 bColor;

#include globals/Fragment3DInputs.glsl
#include globals/Fragment3DOutputs.glsl

#include functions/standardMaterial.glsl

#ifdef ARB_BINDLESS_TEXTURE
layout (location = 20, bindless_sampler) uniform sampler2D bAtlas;
#else
layout(binding = 0) uniform sampler2D bAtlas;
#endif

in vec2 atlasUV;
in flat uint bold;
in flat uint italic;

#include functions/Font.glsl

void main() {

    if(getFontAlpha(bAtlas, atlasUV) < 1e-3) discard;

    normalComposed = normal;
    normalComposed = gl_FrontFacing ? normalComposed : -normalComposed;

    fragColor.rgb = bColor;
    fragEmmisive = vec3(0);

    fragNormal = vec3(1.0);
}
