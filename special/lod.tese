#version 460

layout (triangles, equal_spacing, ccw) in;

#define USING_VERTEX_TEXTURE_UV

#include uniform/Base3D.glsl
#include uniform/Model3D.glsl
#include globals/Vertex3DOutputs.glsl

in vec2 patchUv[];
in vec3 patchPosition[];
in vec3 patchNormal[];

#define DONT_RETREIVE_UV;

#ifdef ARB_BINDLESS_TEXTURE
layout (location = 22, bindless_sampler) uniform sampler2D bHeight;
layout (location = 23, bindless_sampler) uniform sampler2D bDisp;
#else 
layout(binding = 2) uniform sampler2D bHeight;
layout(binding = 3) uniform sampler2D bDisp;
#endif

/*
 The vertex positional data gets sent through the built-in GLSL 
 variables gl_in and gl_out which are both arrays of the following 
 struct type:

    in gl_PerVertex
    {
        vec4 gl_Position;
        float gl_PointSize;
        float gl_ClipDistance[];
    } gl_in[gl_MaxPatchVertices];
*/

vec2 interpolate2D(vec2 v0, vec2 v1, vec2 v2, vec3 coord)
{
    return vec2(coord.x) * v0 + vec2(coord.y) * v1 + vec2(coord.z) * v2;
}

vec3 interpolate3D(vec3 v0, vec3 v1, vec3 v2, vec3 coord)
{
    return vec3(coord.x) * v0 + vec3(coord.y) * v1 + vec3(coord.z) * v2;
} 

void main()
{
    // get patch coordinate
    // float u = gl_TessCoord.x;
    // float v = gl_TessCoord.y;

    // ----------------------------------------------------------------------
    // interpolate texture coordinate across patch
    vec3 hTessCoord = gl_TessCoord;
    // hTessCoord = min(hTessCoord, vec3(0.1));
    // hTessCoord -= mod(hTessCoord, vec3(0.1));

    uv = interpolate2D(patchUv[0], patchUv[1], patchUv[2], hTessCoord);
    float h = texture(bHeight, uv).r - 0.5;
    const float bias = 0.01;
    h += texture(bHeight, uv+vec2(bias, 0)).r - 0.5;
    h += texture(bHeight, uv-vec2(bias, 0)).r - 0.5;
    h += texture(bHeight, uv+vec2(0, bias)).r - 0.5;
    h += texture(bHeight, uv-vec2(0, bias)).r - 0.5;
    h *= 0.0; //0.2

    // retrieve control point position coordinates
    vec3 p1 = patchPosition[0]; vec3 p2 = patchPosition[1]; vec3 p3 = patchPosition[2];

    // compute patch surface normal
    // normal = normalize(cross(p2-p1, p3-p1));
    normal = interpolate3D(patchNormal[0], patchNormal[1], patchNormal[2], hTessCoord);
    vec3 positionInModel = interpolate3D(p1, p2, p3, hTessCoord) + normal*h;

    // ----------------------------------------------------------------------
    const float uvDispFactor = 3.0;
    const float dispAmpl = 0.05; //0.002
    vec2 uvDisp = uv*uvDispFactor;
    float hDisp = texture(bDisp, uvDisp).r;
    positionInModel += dispAmpl * hDisp * normal;
    uv = uvDisp;

    // ----------------------------------------------------------------------
    // output patch point position in clip space
    mat4 modelMatrix = _modelMatrix;
    #include code/SetVertex3DOutputs.glsl
    gl_Position = _cameraMatrix * vec4(position, 1.0);
}
	
