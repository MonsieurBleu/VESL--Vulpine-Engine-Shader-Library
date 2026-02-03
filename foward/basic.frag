#version 460

#include SceneDefines3D 
#define USING_VERTEX_TEXTURE_UV

#include Base3D 
#include Model3D 
#include Ligths 

layout (location = 20) uniform vec3 bColor;

#include Fragment3DInputs 
//include Fragment3DOutputs 

layout(location = 0) out vec4 fragColor;
layout(location = 1) out vec2 fragNormal;
layout(location = 4) out vec3 fragMaterialPosition;
layout(location = 5) out vec4 fragMaterialProperty;

#include standardMaterial 

void main() {
    normalComposed = normal;
    normalComposed = gl_FrontFacing ? normalComposed : -normalComposed;

    fragColor.rgb = bColor;

    // fragNormal = normalize((vec4(normalComposed, 0.0) * inverse(_cameraViewMatrix)).rgb) * 0.5 + 0.5;
    // fragEmmisive = vec3(0);
    // fragNormal = vec3(1, 0, 0);
    fragNormal = vec2(0);
}
