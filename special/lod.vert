#version 460

#ifdef ARB_BINDLESS_TEXTURE
#extension GL_ARB_bindless_texture : require
#endif

#define USING_VERTEX_TEXTURE_UV
#define USING_LOD_TESSELATION

 #include Base3D 
 #include Model3D 

 #include Vertex3DInputs 
 #include Vertex3DOutputs 

// #ifdef ARB_BINDLESS_TEXTURE
// layout (location = 22, bindless_sampler) uniform sampler2D bHeight;
// layout (location = 23, bindless_sampler) uniform sampler2D bDisp;
// #else
// layout(binding = 2) uniform sampler2D bHeight;
// layout(binding = 3) uniform sampler2D bDisp;
// #endif

out vec2 vertexUv;
out vec3 vertexPos; 
out vec3 vertexNormal;

void main()
{
    vertexUv = lodHeigtTextureRange.xy  + vec2(_uv.x , 1.0 - _uv.y)*(lodHeigtTextureRange.zw - lodHeigtTextureRange.xy);
    vertexPos = _positionInModel;
    vertexNormal = _normal;
}