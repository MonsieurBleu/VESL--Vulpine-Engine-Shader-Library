#version 460

#define USING_VERTEX_TEXTURE_UV

 #include Base2D 
 #include Model3D 

layout(location = 0) in vec4 _position;

layout(location = 20) uniform vec4 color;

out float lineDist;

void main()
{
    lineDist = _position.w;

    vec3 position = (_modelMatrix * vec4(_position.xy - vec2(0.0, 1.0), 0, 1.0)).rgb;

    // position.z = _modelMatrix[3].z + 0.01;


    position.z = 0.9;
    position.z = _position.z + 0.01;

    gl_Position = vec4(position, 1.0);
};