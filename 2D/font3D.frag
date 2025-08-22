#version 460

#include SceneDefines3D 
#define USING_VERTEX_TEXTURE_UV

#include SceneDefines3D 

 #include Base3D 
 #include Model3D 
 #include Ligths 

layout (location = 20) uniform vec3 bColor;

 #include Fragment3DInputs 
 #include Fragment3DOutputs 

#include standardMaterial 

#ifdef ARB_BINDLESS_TEXTURE
layout (location = 20, bindless_sampler) uniform sampler2D bAtlas;
#else
layout(binding = 0) uniform sampler2D bAtlas;
#endif

in vec2 atlasUV;
in flat uint bold;
in flat uint italic;

#include Font 

void main() {

    if(getFontAlpha(bAtlas, atlasUV) < 1e-3) discard;

    normalComposed = normal;
    normalComposed = gl_FrontFacing ? normalComposed : -normalComposed;

    fragColor.rgb = bColor.rgb;
    fragEmmisive = vec3(0);

    fragNormal = vec3(1.0);
}
