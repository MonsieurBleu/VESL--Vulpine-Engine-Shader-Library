#version 460

#define USING_VERTEX_TEXTURE_UV

#include uniform/Base3D.glsl
#include uniform/Model3D.glsl

#include globals/Vertex3DInputs.glsl
#include globals/Vertex3DOutputs.glsl

#ifdef ARB_BINDLESS_TEXTURE
layout (location = 22, bindless_sampler) uniform sampler2D bHeight;
#else
layout(binding = 2) uniform sampler2D bHeight;
#endif


void main()
{
    mat4 modelMatrix = _modelMatrix;
    vec3 positionInModel = _positionInModel;
    normal = _normal;

    // positionInModel.y += cos(positionInModel.x + 4.5);
    // positionInModel.y += positionInModel.x;

        
    #ifndef USING_VERTEX_TEXTURE_UV
        color = _color;
    #else
        uv = vec2(_uv.x , 1.0 - _uv.y);
    #endif

    float h0 = texture(bHeight, uv).r;
    float h1 = texture(bHeight, uv + vec2(0.01)).r;
    float h2 = texture(bHeight, uv - vec2(0.01)).r;

    positionInModel += normal*(h0 - 0.5)*2.0;

    vec3 perturb;
    perturb = vec3(1, 0, 0)*(h0-h1) + vec3(0, 0, 1)*(h0-h2);

    normal = normalize(normal + perturb*32.0);


    #include code/SetVertex3DOutputs.glsl
    gl_Position = _cameraMatrix * vec4(position, 1.0);
};