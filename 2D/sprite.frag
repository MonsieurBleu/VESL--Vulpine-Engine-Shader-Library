#version 460

#include uniform/Base3D.glsl
#include uniform/Model3D.glsl

layout (location = 0) out vec4 fragColor;
layout (binding = 0) uniform sampler2D bAtlas;

in vec2 atlasUV;
in vec3 position;
in flat uint bold;
in flat uint italic;

#include functions/Font.glsl

void main()
{
    fragColor = texture(bAtlas, atlasUV);
}