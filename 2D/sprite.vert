#version 460

#define USING_VERTEX_TEXTURE_UV

#include uniform/Base3D.glsl
#include uniform/Model3D.glsl

layout(location = 32) uniform vec3 _textColor;

layout(location = 0) in vec3 _position;
layout(location = 1) in vec2 _atlasUV;
layout(location = 2) in uint _style;

out vec2 atlasUV;
out vec3 position;
out flat uint bold;
out flat uint italic;

void main() {
    bold = (_style & 1u) == 1u ? 1u : 0u;
    italic = (_style & 2u) == 2u ? 1u : 0u;

    atlasUV = _atlasUV / 2048.0;
    atlasUV = vec2(atlasUV.x, 1. - atlasUV.y);

    position = _position;

    if(italic == 1u && (
        gl_VertexID%6 == 0 ||
        gl_VertexID%6 == 1 ||
        // gl_VertexID%6 == 4 ||
        gl_VertexID%6 == 5
    ))
        position.x += 0.005;

    position = (_modelMatrix * vec4(position, 1.0)).rgb;
    position.xy *= vec2(_iResolution.yx) / float(_iResolution.y);


    gl_Position = vec4(position, 1.0);
};