#version 460

#define USING_VERTEX_TEXTURE_UV

#include uniform/Base3D.glsl
#include uniform/Model3D.glsl

// layout(location = 32) uniform vec4 _textColor;

layout(location = 0) in vec3 _position;
layout(location = 1) in vec2 _atlasUV;
layout(location = 2) in uint _style;

#include globals/Vertex3DOutputs.glsl

out vec2 atlasUV;
out flat uint bold;
out flat uint italic;


void main() {
    bold = (_style & 1u) == 1u ? 1u : 0u;
    italic = (_style & 2u) == 2u ? 1u : 0u;

    atlasUV = _atlasUV / 2048.0;
    atlasUV = vec2(atlasUV.x, 1. - atlasUV.y);

    // (inverse(_cameraViewMatrix)

    // mat4 billMat = inverse(_cameraProjectionMatrix);
    // mat4 billMat = mat4(1);

    // position = vec3(_modelMatrix * billMat * vec4(_position, 1.0)).rgb;
    // position.xy *= vec2(_iResolution.yx) / float(_iResolution.y);

    normal = vec3(2.0);

    mat4 ModelView = _cameraViewMatrix * _modelMatrix;

    float scale = length(vec3(_modelMatrix[0][0], _modelMatrix[0][1], _modelMatrix[0][2]));

    // Column 0:
    ModelView[0][0] = scale;
    ModelView[0][1] = 0;
    ModelView[0][2] = 0;

    // Column 1:
    ModelView[1][0] = 0;
    ModelView[1][1] = scale;
    ModelView[1][2] = 0;

    // Column 2:
    ModelView[2][0] = 0;
    ModelView[2][1] = 0;
    ModelView[2][2] = scale;

    gl_Position = _cameraProjectionMatrix * ModelView * vec4(_position, 1.0);
};