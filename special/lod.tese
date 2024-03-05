#version 460

layout (triangles, equal_spacing, ccw) in;
// layout (triangles, fractional_even_spacing, ccw) in;

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
#else
layout(binding = 0) uniform sampler2D b_Color;
layout(binding = 1) uniform sampler2D bMaterial;
layout(binding = 2) uniform sampler2D bHeight;
#endif

#ifdef USING_TERRAIN_RENDERING
#include functions/TerrainTexture.glsl
out vec2 terrainUv;
out float terrainHeight;
#endif

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
    vec3 normalG = normalize(interpolate3D(patchNormal[0], patchNormal[1], patchNormal[2], hTessCoord));
    normal = normalG;
    vec3 positionInModel = interpolate3D(p1, p2, p3, hTessCoord);

    const float zero = 1e-9;

    if(lodHeightDispFactors.w > zero)
    {
        float h = texture(bHeight, clamp(uv*lodHeightDispFactors.z, 0.001, 0.999)).r;
        const float bias = 0.01*lodHeightDispFactors.z;
        float h1 = texture(bHeight, clamp(uv+vec2(bias, 0), 0.001, 0.999)).r;
        float h2 = texture(bHeight, clamp(uv-vec2(bias, 0), 0.001, 0.999)).r;
        float h3 = texture(bHeight, clamp(uv+vec2(0, bias), 0.001, 0.999)).r;
        float h4 = texture(bHeight, clamp(uv-vec2(0, bias), 0.001, 0.999)).r;

        float tessLevel = gl_TessLevelOuter[0];
        // float nbias = 0.01 / pow(tessLevel, 0.25);
        float nbias = 0.01;
        float dist = nbias/lodHeightDispFactors.w;

        float nh1 = h;
        vec3 nP1 = normal*nh1; 
        float nh2 = texture(bHeight, clamp(uv+vec2(0, nbias), 0.001, 0.999)).r;
        float nh3 = texture(bHeight, clamp(uv+vec2(nbias, 0), 0.001, 0.999)).r;
        vec3 nP2 = normal*nh2 + vec3(0.0, 0.0, dist); 
        vec3 nP3 = normal*nh3 + vec3(dist, 0.0, 0.0); 

        float nh4 = texture(bHeight, clamp(uv-vec2(0, nbias), 0.001, 0.999)).r;
        float nh5 = texture(bHeight, clamp(uv-vec2(nbias, 0), 0.001, 0.999)).r; 
        vec3 nP4 = normal*nh4 - vec3(0.0, 0.0, dist); 
        vec3 nP5 = normal*nh5 - vec3(dist, 0.0, 0.0); 

        vec3 n1 = normalize(cross(nP2-nP1, nP3-nP1));
        vec3 n2 = normalize(cross(nP4-nP1, nP5-nP1));
        vec3 n3 = -normalize(cross(nP2-nP1, nP5-nP1));
        vec3 n4 = -normalize(cross(nP4-nP1, nP3-nP1));

        normal = normalize(n1+n2+n3+n4);

    #ifdef USING_TERRAIN_RENDERING
        terrainHeight = h;
        terrainUv = uv*lodHeightDispFactors.z;
    #endif
        const float hfact = 1.0;
        h = (hfact*h+h1+h2+h3+h4)/(hfact+4.0);
        positionInModel += normalG*(h-0.5)*lodHeightDispFactors.w;

    }


    if(lodHeightDispFactors.y > zero)
    {
        vec3 normalDisp = normal;
        const float dispAmpl = lodHeightDispFactors.y; 
        vec2 uvDisp = uv*lodHeightDispFactors.x;

        vec4 factors = getTerrainFactorFromState(normal, terrainHeight);

        float hDisp = 0.5 - getTerrainTexture(factors, uv, bTerrainCE).a;
        
        positionInModel += dispAmpl * hDisp * normalDisp;
        uv = uvDisp;
    }

    mat4 modelMatrix = _modelMatrix;
    #include code/SetVertex3DOutputs.glsl
    gl_Position = _cameraMatrix * vec4(position, 1.0);
}
	
