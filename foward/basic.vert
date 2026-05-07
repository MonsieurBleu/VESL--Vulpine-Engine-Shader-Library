#version 460

// #define USING_VERTEX_TEXTURE_UV

#include Base3D 
#include Model3D 

#include Vertex3DInputs 
#include Vertex3DOutputs 

void main()
{
    vec3 positionInModel = _positionInModel;
    normal = _normal;
    
    #ifdef USING_INSTANCING
    mat4 modelMatrix = _instanceMatrix*_modelMatrix;
    #else
    mat4 modelMatrix = _modelMatrix;
    #endif

    #include SetVertex3DOutputs 
    gl_Position = _cameraMatrix * vec4(position, 1.0);

    #ifdef USING_INSTANCING
    vcolor = vec3(
        fract(_instanceMatrix[0][0])*10.0,
        fract(_instanceMatrix[1][1])*10.0,
        fract(_instanceMatrix[2][2])*10.0
    );
    #endif
};