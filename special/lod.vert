#version 460

#ifdef ARB_BINDLESS_TEXTURE
#extension GL_ARB_bindless_texture : require
#endif

#define USING_VERTEX_TEXTURE_UV
#define USING_LOD_TESSELATION

#include uniform/Base3D.glsl
#include uniform/Model3D.glsl

#include globals/Vertex3DInputs.glsl
#include globals/Vertex3DOutputs.glsl

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
    vertexUv = vec2(_uv.x , 1.0 - _uv.y);
    vertexPos = _positionInModel;
    vertexNormal = _normal;
}