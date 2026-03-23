#version 460

#ifdef ARB_BINDLESS_TEXTURE
#extension GL_ARB_bindless_texture : require
#endif

// layout (triangles, fractional_odd_spacing, ccw) in;
layout (triangles, equal_spacing, ccw) in;
// layout (triangles, fractional_even_spacing, ccw) in;

// #define USING_VERTEX_TEXTURE_UV
#define USING_LOD_TESSELATION
#define USING_VERTEX_PACKING

#include Base3D 
#include Model3D 
#include Vertex3DOutputs 

#include Noise 
#include HSV
#include Hash

in vec2 patchUv[];
in vec3 patchPosition[];
in vec3 patchNormal[];

#define DONT_RETREIVE_UV;

#ifdef ARB_BINDLESS_TEXTURE
    layout (location = 22, bindless_sampler) uniform sampler2D bHeight;
#else
    layout (binding = 2) uniform sampler2D bHeight;
#endif

#ifdef USING_TERRAIN_RENDERING
#include TerrainTexture 
out vec2 terrainUv;
out float terrainHeight;
out vec3 modelPosition;
#endif


#ifdef USING_VERTEX_PACKING

out float vEmmisive;
out float vRoughness;
out float vMetalness;

out float vPaperness;
out float vStreaking;
out float vBloodyness;
out float vDirtyness;

// out vec2 uv;

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

    vec2 uv = interpolate2D(patchUv[0], patchUv[1], patchUv[2], hTessCoord);
    vec3 normalG = normalize(interpolate3D(patchNormal[0], patchNormal[1], patchNormal[2], hTessCoord));
    normal = normalG;
    vec3 positionInModel = interpolate3D(p1, p2, p3, hTessCoord);

    const float zero = 1e-9;

    if(lodHeightDispFactors.w > zero)
    {
        vec2 hUv = uv*lodHeightDispFactors.z;
        float h = texture(bHeight, clamp(hUv, 0.001, 0.999)).r;

        // h = texelFetch(bHeight, ivec2(clamp(hUv, 0.001, 0.999)*4096), 0).r;

        #ifdef USING_TERRAIN_RENDERING
            terrainHeight = h;
            terrainUv = hUv;
        #endif

        float a[6] = float[6](0.1, 0.6, -0.25, -0.48, 0.25, -0.9);

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

        const float f[8] = float[8](1., 1., 1., 1., .5, .5, .5, .5);

        float slope = 1e-9; // TODO : add a slope controlled normal sampling bias
        float htmp = h;

        // for(int i = 0; i < 8; i++)
        // {
        //     // vec2 uvb = 0.01*vec2(a[i], a[i+1]);
        //     vec2 uvb = 0.00005*s[i];
        //     vec2 uvs = clamp(hUv + uvb, vec2(1e-3), vec2(1-1e-3));
        //     float _h = texture(bHeight, uvs).r;

        //     slope = max(slope, abs(htmp-_h))/0.0025;

        //     h += _h*f[i];
        // }
        // h /= 7.0;

        // positionInModel += normalG*(h-0.5)*lodHeightDispFactors.w;
        positionInModel += normalG*(h);
        // positionInModel.y += h;

        slope = clamp(slope, 0, 1);
        slope = pow(slope, 1.0);

        // const float bias = 0.0035*lodHeightDispFactors.z*0.1;
        // const float bias = 0.01*slope*lodHeightDispFactors.z;

        // const float bias = 0.000005;
        const float bias = 1.0/8192.0;

        float h1 = texture(bHeight, clamp(hUv+vec2(bias, 0), 0.001, 0.999)).r;
        float h2 = texture(bHeight, clamp(hUv-vec2(bias, 0), 0.001, 0.999)).r;
        float h3 = texture(bHeight, clamp(hUv+vec2(0, bias), 0.001, 0.999)).r;
        float h4 = texture(bHeight, clamp(hUv-vec2(0, bias), 0.001, 0.999)).r;

        // float dist = 15.0*bias/lodHeightDispFactors.w;
        // float dist = 0.5*bias/lodHeightDispFactors.w;
        // float dist = 0.075*bias/lodHeightDispFactors.w;

        // float dist = 2.0 * bias / lodHeightDispFactors.w;
        // dist *= 0.1;
        float dist = bias * 0.5 * (4096.0/384) * 0.5;
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
            // +n1 
            +n2 
            // +n3 
            +n4 
            );   
    }

    /* Displacement Mapping, unsed for now
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
    */


    


    modelPosition = positionInModel;

    mat4 modelMatrix = _modelMatrix;

    #include SetVertex3DOutputs 


    // position -= normal*0.5 * vec3(1, 0, 1);


    vec4 factors = getTerrainFactorFromState(normal, terrainHeight);

    vcolor = vec3(0);
    const vec3 grassColor = hsv2rgb(vec3(0.20, 0.9, 0.3));
    vcolor = mix(vcolor, grassColor, factors[2]); // grass

    const vec3 dirtCOlor = hsv2rgb(vec3(0.1, 0.8, 0.2));
    vcolor = mix(vcolor, dirtCOlor, factors[3]); // dirt

    const vec3 rockColor = vec3(0xB4, 0xA1, 0x6E)/255.0;
    vcolor = mix(vcolor, rockColor, factors[1]); // rocks

    const vec3 snowColor = vec3(0xD0, 0xD0, 0xff)/255.0;
    vcolor = mix(vcolor, snowColor, factors[0]); // snow


    vRoughness = 0.f;
    vRoughness = mix(vRoughness, 0.6, factors[2]);
    vRoughness = mix(vRoughness, 0.75, factors[3]);
    vRoughness = mix(vRoughness, 0.5, factors[1]);
    vRoughness = mix(vRoughness, 0.75, factors[0]);

    vMetalness = 0.0;


    bool doDetailedTerrain = true;
    float dtd = smoothstep(128.0, 32.0, distance(_cameraPosition, position));
    doDetailedTerrain = dtd > 0.001;
    // doDetailedTerrain = false; 

    if(doDetailedTerrain)
    {
        float sn = snoise(position*0.25);
        sn += snoise(position - 50.0)*0.5;

        vcolor = mix(dirtCOlor, vcolor, factors[2]*smoothstep(1., -1., sn-1.0+dtd-factors[1]));
        vcolor = mix(vcolor, rockColor, 0.25*factors[2]*smoothstep(0.5, 0.9, sn-1.0+dtd));

        // sn *= 1.0-factors[1]*0.75;

        position -= dtd*normal*sn*0.25;

        // float vh = vulpineHash(position.xz, 0.0);
        // float vh = snoise(position*5.0 - 50.0)*0.5 + 0.5;
        

        /* Trying to make rocks */
        float sn2 = snoise(position*0.5 + 5.0);
        // float rockStep = 0.8;
        // float smallRockAlpha = smoothstep(rockStep+0.01, rockStep, sn2);

        // smallRockAlpha += factors[1]*2.0;
        // smallRockAlpha = clamp(smallRockAlpha, 0.0, 1.0);

        // vcolor = mix(rockColor, vcolor, smallRockAlpha);
        // vRoughness = mix(vRoughness, 0.5, vRoughness);

        // position += 0.25*normal*(1.0-smallRockAlpha)*(0.5+0.5*vh);


        vcolor = hsv2rgb(rgb2hsv(vcolor) * (1.0 + dtd*2.0*sn2*vec3(0.01, -0.1, 0.1)));
    }

    #ifdef USING_LAYERED_RENDERING
    gl_Position = vec4(position, 1.0);
    #else
    gl_Position = _cameraMatrix * vec4(position, 1.0);
    #endif
}
	
