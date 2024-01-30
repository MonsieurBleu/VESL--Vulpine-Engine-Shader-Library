#version 460

#define USING_VERTEX_TEXTURE_UV

#include SceneDefines3D.glsl

#ifdef ARB_BINDLESS_TEXTURE
#extension GL_ARB_bindless_texture : require
#endif

#include uniform/Base3D.glsl
#include uniform/Model3D.glsl
#include uniform/Ligths.glsl

layout(location = 20) uniform vec3 bColor;

#include globals/Fragment3DInputs.glsl
#include globals/Fragment3DOutputs.glsl

#include functions/standardMaterial.glsl

void main() {
    normalComposed = normal;
    normalComposed = gl_FrontFacing ? normalComposed : -normalComposed;

    fragColor.rgb = bColor;
    fragEmmisive = getStandardEmmisive(fragColor.rgb);

    fragNormal = normalize((vec4(normalComposed, 0.0) * inverse(_cameraViewMatrix)).rgb) * 0.5 + 0.5;
}
