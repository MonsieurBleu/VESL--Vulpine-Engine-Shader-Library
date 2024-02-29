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
        uv = clamp(uv, vec2(0.001), vec2(0.999));
    #endif

    float h0 = texture(bHeight, uv).r;
    const float hmBias = 0.01;
    float h1 = texture(bHeight, uv + vec2(hmBias, 0.0)).r;
    float h2 = texture(bHeight, uv - vec2(0.0, hmBias)).r;

    const float hmAmplitude = 2.0;

    positionInModel += normal*(h0 - 0.5)*hmAmplitude;

    vec3 modPos2 = _positionInModel + normal*(h1 - 0.5)*hmAmplitude + normal.yxz*hmBias*2.0;
    vec3 modPos3 = _positionInModel + normal*(h2 - 0.5)*hmAmplitude + normal.xzy*hmBias*2.0;;
    normal = cross((modPos3 - positionInModel), (modPos2 - positionInModel));


    // vec3 perturb;
    // perturb = vec3(1, 0, 0)*(h0-h1) + vec3(0, 0, 1)*(h0-h2);

    // normal = normalize(normal + perturb*32.0);




    #include code/SetVertex3DOutputs.glsl
    gl_Position = _cameraMatrix * vec4(position, 1.0);
};