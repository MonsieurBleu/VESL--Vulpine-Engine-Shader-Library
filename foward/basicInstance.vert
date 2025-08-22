#version 460

#define USING_VERTEX_TEXTURE_UV
#define USING_INSTANCING

 #include Base3D 
 #include Model3D 

 #include Vertex3DInputs 
 #include Vertex3DOutputs 



void main()
{
    mat4 modelMatrix = _instanceMatrix;
    vec3 positionInModel = _positionInModel;
    normal = _normal;
     #include SetVertex3DOutputs 
    gl_Position = _cameraMatrix * vec4(position, 1.0);
};