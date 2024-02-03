#version 460

#define USING_VERTEX_TEXTURE_UV

#include uniform/Base3D.glsl
#include uniform/Model3D.glsl

layout (location = 32) uniform vec3 _textColor;

layout (location = 0) in vec3 _position;
layout (location = 1) in vec2 _atlasUV;
layout (location = 2) in uint _style;

out vec2 atlasUV;
out vec3 position;
out flat uint bold;
out flat uint italic;

void main()
{
    uint style = bitfieldReverse(_style);
    bold = (style & 1) == 1 ? 1 : 0;
    italic = (style & 2) == 2 ? 1 : 0;
    
    atlasUV = _atlasUV/2048.0;
    atlasUV = vec2(atlasUV.x, 1.f - atlasUV.y);
    position = (_modelMatrix * vec4(_position, 1.0)).rgb;
    position.xy *= vec2(_iResolution.yx)/float(_iResolution.y);
    gl_Position = vec4(position, 1.0);
};