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
    // vec3 p1 = gl_in[0].gl_Position.xyz; 
    // vec3 p2 = gl_in[1].gl_Position.xyz; 
    // vec3 p3 = gl_in[2].gl_Position.xyz;    

    uv = interpolate2D(patchUv[0], patchUv[1], patchUv[2], hTessCoord);
    vec3 normalG = normalize(interpolate3D(patchNormal[0], patchNormal[1], patchNormal[2], hTessCoord));
    normal = normalG;
    vec3 positionInModel = interpolate3D(p1, p2, p3, hTessCoord);

    const float zero = 1e-9;

    if(lodHeightDispFactors.w > zero)
    {
        float h = texture(bHeight, clamp(uv*lodHeightDispFactors.z, 0.001, 0.999)).r - 0.5;
        // const float bias = 0.005*lodHeightDispFactors.z;
        const float bias = 0.01*lodHeightDispFactors.z;
        float h1 = texture(bHeight, clamp(uv+vec2(bias, 0), 0.001, 0.999)).r - 0.5;
        float h2 = texture(bHeight, clamp(uv-vec2(bias, 0), 0.001, 0.999)).r - 0.5;
        float h3 = texture(bHeight, clamp(uv+vec2(0, bias), 0.001, 0.999)).r - 0.5;
        float h4 = texture(bHeight, clamp(uv-vec2(0, bias), 0.001, 0.999)).r - 0.5;



        float tessLevel = gl_TessLevelOuter[0];
        // float nbias = 0.01 / pow(tessLevel, 0.25);
        float nbias = 0.01;
        float dist = nbias;

        float nh1 = h;
        vec3 nP1 = normal*nh1; 
        
        float nh2 = texture(bHeight, clamp(uv+vec2(0, nbias), 0.001, 0.999)).r - 0.5;
        float nh3 = texture(bHeight, clamp(uv+vec2(nbias, 0), 0.001, 0.999)).r - 0.5;
        vec3 nP2 = normal*nh2 + vec3(0.0, 0.0, dist); 
        vec3 nP3 = normal*nh3 + vec3(dist, 0.0, 0.0); 

        float nh4 = texture(bHeight, clamp(uv-vec2(0, nbias), 0.001, 0.999)).r - 0.5;
        float nh5 = texture(bHeight, clamp(uv-vec2(nbias, 0), 0.001, 0.999)).r - 0.5; 
        vec3 nP4 = normal*nh4 - vec3(0.0, 0.0, dist); 
        vec3 nP5 = normal*nh5 - vec3(dist, 0.0, 0.0); 

        vec3 n1 = normalize(cross(nP2-nP1, nP3-nP1));
        vec3 n2 = normalize(cross(nP4-nP1, nP5-nP1));
        vec3 n3 = -normalize(cross(nP2-nP1, nP5-nP1));
        vec3 n4 = -normalize(cross(nP4-nP1, nP3-nP1));

        normal = normalize(n1+n2+n3+n4);

        h = (h+h1+h2+h3+h4)*0.2*lodHeightDispFactors.w;
        positionInModel += normalG*h;
    }


    if(lodHeightDispFactors.y > zero)
    {
        // vec3 normalDisp = normalize(cross(p2-p1, p3-p1));
        // normalDisp = normal;
        vec3 normalDisp = normalG;

        const float dispAmpl = lodHeightDispFactors.y; 
        vec2 uvDisp = uv*lodHeightDispFactors.x;
        // float hDisp = texture(bDisp, uvDisp).r;
        float hDisp = texture(b_Color, uvDisp).a;
        positionInModel += dispAmpl * hDisp * normalDisp;
        uv = uvDisp;
    }

    // normal = normalize(cross(p2-p1, p3-p1));
    // normal = vec3(1, 0, 0);

    mat4 modelMatrix = _modelMatrix;
    #include code/SetVertex3DOutputs.glsl
    
    // normal = normalize(cross(
    //     gl_in[1].gl_Position.xyz - gl_in[0].gl_Position.xyz,
    //     gl_in[2].gl_Position.xyz - gl_in[0].gl_Position.xyz
    // ));
    
    gl_Position = _cameraMatrix * vec4(position, 1.0);
}
	
