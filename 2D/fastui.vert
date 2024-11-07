#version 460

#include uniform/Base2D.glsl
#include uniform/Model3D.glsl

layout (location = 0) in vec4 _position;
layout (location = 1) in vec4 _color;
layout (location = 2) in vec4 _uvType;

out vec2 uv;
out vec4 color;
out flat int type;
out float aspectRatio;
out float scale;

void main()
{
    uv = _uvType.xy;
    color = _color;
    type = int(_uvType.z);

    aspectRatio = _uvType.a * float(_iResolution.x)/float(_iResolution.y);

    scale = _position.z;


    vec3 position = (_modelMatrix * vec4(vec3(_position) * vec3(1, 1, 0), 1.0)).rgb;
    // position.xy *= vec2(_iResolution.yx)/float(_iResolution.y);
    position.z = _position.w + 0.01;

    gl_Position = vec4(position, 1.0);
}

