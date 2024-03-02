#version 460

#define USING_VERTEX_TEXTURE_UV
#define USING_INSTANCING

#include uniform/Base3D.glsl
#include uniform/Model3D.glsl

#include globals/Vertex3DInputs.glsl
#include globals/Vertex3DOutputs.glsl



void main()
{
    mat4 modelMatrix = _instanceMatrix;
    vec3 positionInModel = _positionInModel;
    normal = _normal;
    #include code/SetVertex3DOutputs.glsl
    gl_Position = _cameraMatrix * vec4(position, 1.0);
};