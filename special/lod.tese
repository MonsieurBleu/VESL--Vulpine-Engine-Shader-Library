#version 460

#ifdef ARB_BINDLESS_TEXTURE
#extension GL_ARB_bindless_texture : require
#endif

layout (triangles, equal_spacing, ccw) in;
// layout (triangles, fractional_even_spacing, ccw) in;

#define USING_VERTEX_TEXTURE_UV
#define USING_LOD_TESSELATION

#include uniform/Base3D.glsl
#include uniform/Model3D.glsl
#include globals/Vertex3DOutputs.glsl

#include functions/Noise.glsl

in vec2 patchUv[];
in vec3 patchPosition[];
in vec3 patchNormal[];

#define DONT_RETREIVE_UV;

#ifdef ARB_BINDLESS_TEXTURE
    layout (location = 20, bindless_sampler) uniform sampler2D bColor;
    // layout (location = 21, bindless_sampler) uniform sampler2D bMaterial;
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
out vec3 modelPosition;
#endif

vec2 interpolate2D(vec2 v0, vec2 v1, vec2 v2, vec3 coord)
{
    return vec2(coord.x) * v0 + vec2(coord.y) * v1 + vec2(coord.z) * v2;
}

vec3 interpolate3D(vec3 v0, vec3 v1, vec3 v2, vec3 coord)
{
    return vec3(coord.x) * v0 + vec3(coord.y) * v1 + vec3(coord.z) * v2;
} 

vec3 clamp3D(vec3 inp, float val)
{
    return ceil(inp*val)/val;
}

void main()
{
    terrainHeight = 0.f;

    vec3 hTessCoord = gl_TessCoord;
    vec3 p1 = patchPosition[0]; vec3 p2 = patchPosition[1]; vec3 p3 = patchPosition[2];  

    uv = interpolate2D(patchUv[0], patchUv[1], patchUv[2], hTessCoord);
    vec3 normalG = normalize(interpolate3D(patchNormal[0], patchNormal[1], patchNormal[2], hTessCoord));
    normal = normalG;
    vec3 positionInModel = interpolate3D(p1, p2, p3, hTessCoord);

    const float zero = 1e-9;

    if(lodHeightDispFactors.w > zero)
    {
        vec2 hUv = uv*lodHeightDispFactors.z;
        
        float h = texture(bHeight, clamp(hUv, 0.001, 0.999)).r;



    #ifdef USING_TERRAIN_RENDERING
        terrainHeight = h;
        terrainUv = hUv;
    #endif
        const float hfact = 1.0;
        // h = (hfact*h+h1+h2+h3+h4)/(hfact+4.0);

        float _h2 = texture(bHeight, clamp(hUv + vec2(0.01), 1e-3, 0.999)).r;

        // for(int i = 1; i <= 16; i++)
        // {
        //     vec2 uvb = 0.01*(1.0 - 2.0*vor3d_hash(i).xy);
        //     vec2 uvs = clamp(hUv + uvb, vec2(1e-3), vec2(1-1e-3));
        //     float _h = texture(bHeight, uvs).r;

        //     h = mix(h, _h, 0.1);
        // }


        float a[6] = float[6](0.1, 0.6, -0.25, -0.48, 0.25, -0.9);
        // float a[6] = float[6](1.0, 0.0, -1.0, 0.0, 1.0, 0.5);

        vec2 s[8] = vec2[8](
            vec2( 1.,  1.),
            vec2( 1., -1.),
            vec2(-1.,  1.),
            vec2(-1., -1.),

            vec2( .5,  .5),
            vec2( .5, -.5),
            vec2(-.5,  .5),
            vec2(-.5, -.5)
        );

        const float f[8] = const float[8](1., 1., 1., 1., .5, .5, .5, .5);

        // normal = vec3(0);

        // for(int i = 0; i < 5; i++)
        // {
        //     float scale = 0.01;

        //     vec2 uvb = scale*vec2(a[i], a[i+1]);
        //     vec2 uvs = clamp(hUv + uvb, vec2(1e-3), vec2(1-1e-3));
        //     float _h = texture(bHeight, uvs).r;

        //     // vec2 uvb2 = -scale*vec2(a[i+1], a[i]);
        //     vec2 uvb2 = uvb.yx;
        //     vec2 uvs2 = clamp(hUv + uvb2, vec2(1e-3), vec2(1-1e-3));
        //     float _h2 = texture(bHeight, uvs2).r;

        //     vec3 nP1 = vec3(0, 1, 0)*h;
        //     vec3 nP2 = vec3(0, 1, 0)*_h + vec3(uvb.x, 0, uvb.y);
        //     vec3 nP3 = vec3(0, 1, 0)*_h2 + vec3(uvb2.x, 0, uvb2.y);
        //     // vec3 nP1 = vec3(0, h, 0)*lodHeightDispFactors.w;
        //     // vec3 nP2 = vec3(uvb.x, _h, uvb.y)*lodHeightDispFactors.w;
        //     // vec3 nP3 = vec3(uvb2.x, _h2, uvb2.y)*lodHeightDispFactors.w;

        //     vec3 _n = 0.5 + 0.5*normalize(cross(nP2-nP1, nP3-nP1));

        //     // normal = _n;

        //     if(i == 0) normal = _n;
        //     else
        //     {
        //         // normal = normalize((normal + _n));
        //         // normal = normalize(mix(normal, normalize(_n), 0.5));
        //         // normal *= _n;
        //         // normal += _n;
        //     }
        // }
    

        // normal /= 5.0;
        // normal = sign(normal)*normalize(clamp3D(abs(normal), 20));
        // normal = normalize(normal);

        float slope = 1e-9; // TODO : add a slope controlled normal sampling bias
        float htmp = h;

        for(int i = 0; i < 8; i++)
        {
            // vec2 uvb = 0.01*vec2(a[i], a[i+1]);
            vec2 uvb = 0.0025*s[i];
            vec2 uvs = clamp(hUv + uvb, vec2(1e-3), vec2(1-1e-3));
            float _h = texture(bHeight, uvs).r;

            slope = max(slope, abs(htmp-_h))/0.0025;

            h += _h*f[i];
        }
        h /= 7.0;

        // h = texture(bHeight, clamp(hUv, 0.001, 0.999)).r;
        positionInModel += normalG*(h-0.5)*lodHeightDispFactors.w;

        slope = clamp(slope, 0, 1);
        slope = pow(slope, 1.0);

        const float bias = 0.0035*lodHeightDispFactors.z;
        // const float bias = 0.01*slope*lodHeightDispFactors.z;

        float h1 = texture(bHeight, clamp(hUv+vec2(bias, 0), 0.001, 0.999)).r;
        float h2 = texture(bHeight, clamp(hUv-vec2(bias, 0), 0.001, 0.999)).r;
        float h3 = texture(bHeight, clamp(hUv+vec2(0, bias), 0.001, 0.999)).r;
        float h4 = texture(bHeight, clamp(hUv-vec2(0, bias), 0.001, 0.999)).r;

        float dist = 10.0*bias/lodHeightDispFactors.w;
        vec3 nP1 = normal*h; 
        vec3 nP2 = normal*h3 + vec3(0.0, 0.0, dist); 
        vec3 nP3 = normal*h1 + vec3(dist, 0.0, 0.0); 
        vec3 nP4 = normal*h4 - vec3(0.0, 0.0, dist); 
        vec3 nP5 = normal*h2 - vec3(dist, 0.0, 0.0); 
        vec3 n1 = normalize(cross(nP2-nP1, nP3-nP1));
        vec3 n2 = normalize(cross(nP4-nP1, nP5-nP1));
        vec3 n3 = -normalize(cross(nP2-nP1, nP5-nP1));
        vec3 n4 = -normalize(cross(nP4-nP1, nP3-nP1));
        normal = normalize(
            +n1 
            +n2 
            +n3 
            +n4 
            );
        // normal = n4;



        
    }


    if(lodHeightDispFactors.y > zero)
    {
        vec3 normalDisp = normal;
        const float dispAmpl = lodHeightDispFactors.y; 
        vec2 uvDisp = uv*lodHeightDispFactors.x;

        vec4 factors = getTerrainFactorFromState(normal, terrainHeight);

        float hDisp = 0.5 - getTerrainTexture(factors, uvDisp, bTerrainCE).a;
        
        positionInModel += dispAmpl * hDisp * normalDisp;
        uv = uvDisp;
    }

    modelPosition = positionInModel;

    mat4 modelMatrix = _modelMatrix;
    #include code/SetVertex3DOutputs.glsl
    gl_Position = _cameraMatrix * vec4(position, 1.0);
}
	
