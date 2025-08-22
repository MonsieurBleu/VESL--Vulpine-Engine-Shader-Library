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
 #include Fragment3DOutputs 

#include standardMaterial 
#include Noise 
#include Skybox 

in vec3 viewPos;





void main()
{
    vec3 dir = -normalize(normal);

    switch(skyboxType)
    {
        case 1 : 
            int it = 16;
            for(int i = 0; i < it; i++)
            {
                vec3 r = dir + rand3to3(vec3(i) * 0.1 + abs(dir))*0.05;
                fragColor.rgb += getAmbientInteriorColor(normalize(r));
            }
            fragColor.rgb /= it;
            fragNormal = vec3(0);
        break;

        case 2  : fragColor.rgb = vec3(53,  49,  48)/255.;
        fragNormal = vec3(1);
        break;

        case 3  : fragColor.rgb = vec3(242, 234,  222)/255.;
        fragNormal = vec3(1);
        break;

        case 4  : fragColor.rgb = vec3(100, 175, 200)/255.;
        fragNormal = vec3(1);
        break;

        case 5  : fragColor.rgb = vec3(0, 200, 0)/255.;
        fragNormal = vec3(1);
        break;

        default : 
        
        // dir.y = clamp(dir.y, 0., 1.);
        // dir = normalize(dir);

        if(dir.y < 0)
        {
            dir.y *= -1;
            fragColor.rgb = clamp(getAtmopshereColor(dir), vec3(0), vec3(1));
        }
        else
        {
            getSkyColors(dir, fragColor.rgb, fragEmmisive.rgb);
        }

        fragNormal = vec3(0);
        break;


    }

    // fragColor.rgb = getAmbientInteriorColor(dir);

    


    // fragColor.a = 1.0;
}
