#version 460

#include uniform/Base3D.glsl
#include uniform/Model3D.glsl



layout (location = 0) out vec4 fragColor;
layout (binding = 0) uniform sampler2D bAtlas;

layout (location = 32) uniform vec3 _textColor;

in vec2 atlasUV;
in vec3 position;
in flat uint bold;
in flat uint italic;

#include functions/Font.glsl

void main()
{
    vec3 bodyColor = _textColor;

    bodyColor = bold > 0 ? bodyColor*0.75 : bodyColor;

    vec3 outlineColor = vec3(0.f);

    float opacity = getFontAlpha(bAtlas, atlasUV);

    fragColor = vec4(bodyColor, opacity*2.0);
    
    if(opacity < 1e-2) discard;
}