#version 460

#include SceneDefines3D 

#ifndef USING_INSTANCING
#define USING_VERTEX_TEXTURE_UV
layout (location = 20) uniform vec3 bColor;
#endif

#include Base3D 
#include Model3D 
#include Ligths 


#include Fragment3DInputs 
//include Fragment3DOutputs 

layout(location = 0) out vec4 fragColor;
layout(location = 1) out vec2 fragNormal;
layout(location = 4) out vec3 fragMaterialPosition;
layout(location = 5) out vec4 fragMaterialProperty;

#include standardMaterial 
#include Noise

vec2 compressNormal(vec3 n)
{
    n /= (abs(n.x) + abs(n.y) + abs(n.z));

    if (n.z < 0.0)
        n.xy = (1.0 - abs(n.yx)) * sign(n.xy);

    return n.xy*.5 + .5;
}


void main() {
    normalComposed = normal;
    normalComposed = gl_FrontFacing ? normalComposed : -normalComposed;
    
    #ifndef USING_INSTANCING
    fragColor.rgb = bColor;
    #else 
    fragColor.rgb = vcolor;
    #endif

    ivec2 iuv = ivec2(gl_FragCoord);

    // if(iuv.x%2 == iuv.y%2) discard;

    const int gridSize = 2;
    int score = max(iuv.x%gridSize, iuv.y%gridSize);
    if(score < gridSize/2) discard;

    // float score2 = vulpineHash3D(position, 0.)-0.5;
    // score += score2*0.1;
    // if(score < 1.0) discard;

    // fragColor.rgb = normal;

    // const float size = 0.05;
    // vec3 p = mod(position, size);
    // score = max(p.x, max(p.y, p.z));
    // if(score > size*0.75) discard;

    // fragMaterialPosition = vec3(0.0);
    // fragMaterialProperty = vec4(-1.);

    // fragNormal = normalize((vec4(normalComposed, 0.0) * inverse(_cameraViewMatrix)).rgb) * 0.5 + 0.5;
    // fragEmmisive = vec3(0);
    // fragNormal = vec2(normalComposed);

    // fragNormal = compressNormal(normalComposed);
    // fragColor.rgb = bColor;
    fragNormal = vec2(0);
}
