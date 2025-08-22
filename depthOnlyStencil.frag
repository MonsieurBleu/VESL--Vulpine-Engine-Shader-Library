#version 460

#include SceneDefines3D 
#define USING_VERTEX_TEXTURE_UV


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

#include standardMaterial 

void main()
{
    vec4 NRM = texture(bMaterial, uv);
    if(NRM.x <= 0.01 && NRM.y <= 0.01) discard;
}
