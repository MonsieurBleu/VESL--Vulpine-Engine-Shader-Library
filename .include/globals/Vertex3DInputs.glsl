

#ifdef USING_VERTEX_PACKING

    layout (location = 0) in uvec4 _data;

#else

    layout (location = 0) in vec3 _positionInModel;
    layout (location = 1) in vec3 _normal;

    #ifndef USING_VERTEX_TEXTURE_UV
        layout (location = 2) in vec3 _color;
    #else
        layout (location = 2) in vec2 _uv;
    #endif

#endif

#ifdef USING_INSTANCING
    layout (location = 3) in mat4 _instanceMatrix;
#endif

#ifdef USE_SKINNING 
layout (location = 5) in ivec4 _weightsID;
layout (location = 6) in vec4 _weights;

layout (std430, binding = 2) readonly buffer animationStateBuffer
{
    mat4 animationState[];
};
#endif