#version 460

layout (triangles, equal_spacing, ccw) in;

#define USING_VERTEX_TEXTURE_UV
#define USING_LOD_TESSELATION

#include uniform/Base3D.glsl
#include uniform/Model3D.glsl
#include globals/Vertex3DOutputs.glsl

in vec2 patchUv[];
in vec3 patchPosition[];
in vec3 patchNormal[];

#define DONT_RETREIVE_UV;

#ifdef ARB_BINDLESS_TEXTURE
layout (location = 20, bindless_sampler) uniform sampler2D bColor;
layout (location = 21, bindless_sampler) uniform sampler2D bMaterial;
layout (location = 22, bindless_sampler) uniform sampler2D bHeight;
layout (location = 23, bindless_sampler) uniform sampler2D bDisp;
#else
layout(binding = 0) uniform sampler2D b_Color;
layout(binding = 1) uniform sampler2D bMaterial;
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

    vec3 hTessCoord = gl_TessCoord;
    vec3 p1 = patchPosition[0]; vec3 p2 = patchPosition[1]; vec3 p3 = patchPosition[2];

    uv = interpolate2D(patchUv[0], patchUv[1], patchUv[2], hTessCoord);
    normal = interpolate3D(patchNormal[0], patchNormal[1], patchNormal[2], hTessCoord);
    vec3 positionInModel = interpolate3D(p1, p2, p3, hTessCoord);

    const float zero = 1e-9;

    if(lodHeightDispFactors.w > zero)
    {
        float h = texture(bHeight, clamp(uv*lodHeightDispFactors.z, 0.001, 0.999)).r;
        const float bias = 0.005*lodHeightDispFactors.z;
        h += texture(bHeight, clamp(uv+vec2(bias, 0), 0.001, 0.999)).r - 0.5;
        h += texture(bHeight, clamp(uv-vec2(bias, 0), 0.001, 0.999)).r - 0.5;
        h += texture(bHeight, clamp(uv+vec2(0, bias), 0.001, 0.999)).r - 0.5;
        h += texture(bHeight, clamp(uv-vec2(0, bias), 0.001, 0.999)).r - 0.5;
        h *= 0.2 * lodHeightDispFactors.w;
        positionInModel += normal*h;
    }

    if(lodHeightDispFactors.y > zero)
    {
        vec3 normalDisp = normalize(cross(p2-p1, p3-p1));
        normalDisp = normal;

        const float dispAmpl = lodHeightDispFactors.y; 
        vec2 uvDisp = uv*lodHeightDispFactors.x;
        // float hDisp = texture(bDisp, uvDisp).r;
        float hDisp = texture(b_Color, uvDisp).a - 0.5;
        positionInModel += dispAmpl * hDisp * normalDisp;
        uv = uvDisp;
    }

    mat4 modelMatrix = _modelMatrix;
    #include code/SetVertex3DOutputs.glsl
    gl_Position = _cameraMatrix * vec4(position, 1.0);
}
	
