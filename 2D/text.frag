#version 460

#include uniform/Base3D.glsl
#include uniform/Model3D.glsl

layout (location = 0) out vec4 fragColor;
layout (binding = 0) uniform sampler2D bAtlas;

layout (location = 32) uniform vec4 _textColor;

in vec2 atlasUV;
in vec3 position;
in flat uint bold;
in flat uint italic;

#include functions/Font.glsl

void main()
{
    vec3 bodyColor = _textColor.rgb;

    // bodyColor = bold > 0 ? bodyColor*vec3(0.5, 1.4, 2.5) : bodyColor;
    bodyColor = bold > 0 ? bodyColor*vec3(0.75, 0.75, 0.75) : bodyColor;

    vec3 outlineColor = italic > 0 ? bodyColor*0.2 : bodyColor*0.4;

    vec4 texel = texture(bAtlas, atlasUV);
    float dist = median(texel.r, texel.g, texel.b);

    // float pxRange = 0.4;
    // float pxDist = pxRange * (dist - 0.5);
    // float opacity = smoothstep(-0.5, 0.25, pxDist);
    // float opacity = smoothstep(-pxRange, pxRange*2, pxDist);

    float outer = smoothstep(-0.01, 0.15, dist);
    float inner = smoothstep(0.0, 1.0, dist);

    // bodyColor = mix(outlineColor, bodyColor, pow(inner, 1.0));

    float opacity = outer;

    // fragColor = vec4(dist, dist, dist, 1.0);

    fragColor = vec4(bodyColor, opacity);
    
    // if(opacity < 1e-2) discard;

    fragColor.a *= _textColor.a;
    if(fragColor.a == 0.f) discard;
}