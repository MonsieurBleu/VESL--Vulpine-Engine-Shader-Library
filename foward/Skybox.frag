#version 460

#include SceneDefines3D 

#ifdef ARB_BINDLESS_TEXTURE
#extension GL_ARB_bindless_texture : require
#endif

#define USING_VERTEX_TEXTURE_UV

 #include Base3D 
 #include Model3D 
 #include Ligths 

#ifdef ARB_BINDLESS_TEXTURE
layout (location = 20, bindless_sampler) uniform sampler2D bTexture;
#else
layout (binding = 0) uniform sampler2D bTexture;
#endif

layout (location = 32) uniform int skyboxType;

#include Fragment3DInputs 
//include Fragment3DOutputs 
// layout(location = 3) out vec3 fragMaterialPosition;
// layout(location = 4) out vec3 fragWorldPosition;
// layout(location = 5) out vec4 fragMaterialProperty;
layout(location = 0) out vec4 fragColor;
layout(location = 1) out vec2 fragNormal;
layout(location = 4) out vec3 fragMaterialPosition;
layout(location = 5) out vec4 fragMaterialProperty;

#include standardMaterial 
#include Noise 
#include Skybox 

in vec3 viewPos;



vec2 compressNormal(vec3 n)
{
    n /= (abs(n.x) + abs(n.y) + abs(n.z));

    if (n.z < 0.0)
        n.xy = (1.0 - abs(n.yx)) * sign(n.xy);

    return n.xy*.5 + .5;
}


void main()
{
    fragNormal = compressNormal(normal);
    // fragColor.rgb = getAmbientInteriorColor(dir);

    // fragNormal = normal;
    // fragWorldPosition = position;
    // fragMaterialPosition = position/1000000.0;
    // fragMaterialPosition = position*0.01;
    fragMaterialPosition = vec3(0.0);
    fragMaterialProperty = vec4(-1.);

    // fragColor.rgb = vec3(0, 0.5, 0.5);

    fragColor.rgb = vec3(0);

    // fragMaterialPosition = vec3(1);

    // fragColor.a = 1.0;
}
