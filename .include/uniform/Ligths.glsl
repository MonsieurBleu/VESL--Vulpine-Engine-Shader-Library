struct Light
{
    vec4 position;     
    vec4 color;         
    vec4 direction;       
    ivec4 infos;  
    mat4 matrix;
};

layout (std430, binding = 0) readonly buffer lightsBuffer 
{
    Light lights[];
};

#ifdef USE_CLUSTERED_RENDERING
    layout (std430, binding = 1) readonly buffer lightsBuffer 
    {
        uint lightsID[];
    };
#endif

layout (location = 15) uniform vec3 ambientLight;

layout (binding = 16) uniform sampler2D bShadowMaps[16];


