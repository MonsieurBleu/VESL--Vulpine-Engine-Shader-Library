#version 460

#define USING_VERTEX_TEXTURE_UV
#define USE_SKINNING 

#include uniform/Base3D.glsl
#include uniform/Model3D.glsl

#include globals/Vertex3DInputs.glsl
#include globals/Vertex3DOutputs.glsl

layout (std430, binding = 3) readonly buffer defaultBoneStateBuffer
{
    mat4 defaultBoneState[];
};

void main()
{
    mat4 modelMatrix = _modelMatrix;
    mat4 animMatrix = mat4(0);
    vec3 positionInModel = vec3(0.0);
    normal = vec3(0);
    
    // if(_weights[0] < 1e-6)
    // {
        for(int i = 0; i < 4; i++)
        {
            if(_weights[i] < 1e-6) break;
            // animMatrix = animationState[_weightsID[i]] * inverse(defaultBoneState[_weightsID[i]]);
            animMatrix = animationState[_weightsID[i]];
            positionInModel += _weights[i]*vec3(animMatrix * vec4(_positionInModel, 1.0));
            normal += _weights[i]*mat3(animMatrix)*_normal;
        }
    // }
    // else
    // {
    //     positionInModel = _positionInModel;
    //     normal = _normal;
    // }


    // mat4 f = animMatrix; 
    // normal = mat3(f) * _normal;

    #include code/SetVertex3DOutputs.glsl
    gl_Position = _cameraMatrix * vec4(position, 1.0);
};