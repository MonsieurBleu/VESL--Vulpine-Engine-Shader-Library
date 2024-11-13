#version 460

#include uniform/Base2D.glsl
#include uniform/Model3D.glsl

layout (location = 0) out vec4 fragColor;

layout(location = 20) uniform vec4 color;

in float lineDist;

void main()
{

    // float d = smoothstep(0, 1, lineDist);
    float d = lineDist;

    // d = pow(1.0 - d, 32.0);

    d = pow(1.0 - d, 2.0);

    fragColor.rgb = color.rgb;
    fragColor.a = color.a*d*2.0;
}