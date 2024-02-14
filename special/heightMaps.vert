#version 460

#define USING_VERTEX_TEXTURE_UV

#include uniform/Base3D.glsl
#include uniform/Model3D.glsl

#include globals/Vertex3DInputs.glsl
#include globals/Vertex3DOutputs.glsl

void main()
{
    mat4 modelMatrix = _modelMatrix;
    vec3 positionInModel = _positionInModel;

    positionInModel.y += cos(positionInModel.x + 4.5);
    // positionInModel.y += positionInModel.x;
        
    #ifndef USING_VERTEX_TEXTURE_UV
        color = _color;
    #else
        uv = vec2(_uv.x , 1.0 - _uv.y);
    #endif

    normal = normalize(modelMatrix * vec4(_normal, 0.0)).rgb;
    position = (modelMatrix * vec4(positionInModel, 1.0)).rgb;
    viewVector = _cameraPosition - position;


    gl_Position = _cameraMatrix * vec4(position, 1.0);
};