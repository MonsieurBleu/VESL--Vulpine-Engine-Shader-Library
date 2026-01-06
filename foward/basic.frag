#version 460

#include SceneDefines3D 
#define USING_VERTEX_TEXTURE_UV

#include SceneDefines3D 

 #include Base3D 
 #include Model3D 
 #include Ligths 

layout (location = 20) uniform vec3 bColor;

 #include Fragment3DInputs 
 #include Fragment3DOutputs 

#include standardMaterial 

void main() {
    normalComposed = normal;
    normalComposed = gl_FrontFacing ? normalComposed : -normalComposed;

    fragColor.rgb = bColor;

    // fragNormal = normalize((vec4(normalComposed, 0.0) * inverse(_cameraViewMatrix)).rgb) * 0.5 + 0.5;
    fragEmmisive = vec3(0);
    // fragNormal = vec3(1, 0, 0);
    fragNormal = normalComposed;
}
