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

layout(location = 36) uniform int   editorActive;
layout(location = 37) uniform int   editoreditorTextureView;
layout(location = 38) uniform float editorBrushRange;
layout(location = 39) uniform vec3  editorBrushPos;
layout(location = 40) uniform vec3  editorBrushColor;
layout(location = 41) uniform float editorBrushForce;
layout(location = 42) uniform float editorBrushIntensity;
layout(location = 43) uniform int   target;

#include Base3D 
#include Model3D 
#include Vertex3DOutputs 

#include Noise 
#include HSV
#include Hash
#include Steps

in vec2 patchUv[];
in vec3 patchPosition[];
in vec3 patchNormal[];

#define DONT_RETREIVE_UV;

#ifdef ARB_BINDLESS_TEXTURE
    layout (location = 22, bindless_sampler) uniform sampler2D bHeight;
    layout (location = 23, bindless_sampler) uniform sampler2D bGrassyness;
#else
    layout (binding = 2) uniform sampler2D bHeight;
    layout (binding = 3) uniform sampler2D bGrassyness;
    layout (binding = 4) uniform sampler2D bEditorTexture;
    layout (binding = 5) uniform sampler2D bWaterLevel;
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

    vec2 hUv = uv*lodHeightDispFactors.z;
    float h = texture(bHeight, clamp(hUv, 0.001, 0.999)).r;
    if(lodHeightDispFactors.w > zero)
    {
        // h = textureLod(bHeight, clamp(hUv, 0.001, 0.999), 0).r;
        // h = 
        //     (
        //         texelFetch(bHeight, ivec2(round(clamp(hUv, 0.001, 0.999)*4096)), 0).r
        //         // +
        //         // texelFetch(bHeight, ivec2(clamp(hUv, 0.001, 0.999)*4096) + 1, 0).r
        //         // +
        //         // texelFetch(bHeight, ivec2(clamp(hUv, 0.001, 0.999)*4096) - 1, 0).r
        //     )
        //     /1.f
        //     ;

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
        // positionInModel += cos(length(positionInModel))*2.0 - 0.5;
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
        vec3 nP1 = 3.0*normal*h; 
        vec3 nP2 = 3.0*normal*h3 + vec3(0.0, 0.0, dist); 
        vec3 nP3 = 3.0*normal*h1 + vec3(dist, 0.0, 0.0); 
        vec3 nP4 = 3.0*normal*h4 - vec3(0.0, 0.0, dist); 
        vec3 nP5 = 3.0*normal*h2 - vec3(dist, 0.0, 0.0); 
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

    float grassyness = texture(bGrassyness, 0.5 + position.xz/4096.0).r;
    factors[2] *= smoothstep(0.0, 0.2, grassyness);
    // factors[3] += 0.25*smoothstep(0.0, 0.25, grassyness);

    const vec3 dirtCOlor = hsv2rgb(vec3(0.1, 0.8, 0.2));
    const vec3 dirtCOlor2 = hsv2rgb(vec3(0.1, 0.7, 0.4));
    vec3 grassColor = hsv2rgb(vec3(0.19, 1.0, 0.5));
    // const vec3 grassColor = hsv2rgb(vec3(0.2, 1.0, 0.75));
    const vec3 rockColor = vec3(0xB4, 0xA1, 0x6E)/255.0;
    const vec3 snowColor = vec3(0xD0, 0xD0, 0xff)/255.0;

    float waterLevel = texture(bWaterLevel, 0.5 + position.xz/4096.0).r*512.0;
    float isInWater = step(h*512.0, waterLevel);

    grassColor = mix(grassColor, hsv2rgb(vec3(0.4, 0.5, 0.25)), isInWater);

    vcolor = dirtCOlor2;


    vcolor = mix(vcolor, grassColor, factors[2]); // grass

    vcolor = mix(vcolor, dirtCOlor, factors[3]); // dirt

    vcolor = mix(vcolor, rockColor, factors[1]); // rocks

    vcolor = mix(vcolor, snowColor, factors[0]); // snow


    vRoughness = 1.f;
    vRoughness = mix(vRoughness, 0.5, factors[2]);
    vRoughness = mix(vRoughness, 0.75, factors[3]);
    vRoughness = mix(vRoughness, 0.6, factors[1]);
    vRoughness = mix(vRoughness, 0.75, factors[0]);

    vRoughness = 0.5;

    vMetalness = 1.0;
    // vMetalness = mix(0.0, 1.0, factors[1]*5.0);


    bool doDetailedTerrain = true;
    float dtd = smoothstep(256.0, 32.0, distance(_cameraPosition, position));
    doDetailedTerrain = dtd > 0.001;
    // doDetailedTerrain = false; 

    // position = position.zyx*vec3(-1, 1, 1);
    // normal *= -1;
    // position.xz += 256;
    // vec3 cpos = vec3(inverse(_cameraViewMatrix) * vec4(0, 0, 0, 1));
    // vec3 cpos = _cameraPosition;
    // vcolor = vec3(distance(position, cpos).r, 0, 0);
    // vcolor = position/2048.0;

    vec3 originalNormal = normal;

    if(doDetailedTerrain)
    {
        float sn = snoise(position*2.0 * 1.0)*0.5;
        // sn += snoise(position*8.0 - 50.0)*0.5;
        // sn *=0.5;
        float sn2 = snoise(position*0.5*2.0 + 5.0);
        // sn *= abs(sn2);
        // sn *= 1.5;

        // sn2 = 0;


        vcolor = mix(
            dirtCOlor2, 
            vcolor, 
                factors[2]
                *smoothstep(1., -0., 
                    sn
                    
                    -1.0+dtd-factors[1]

                    + (1.0-grassyness)*0.5
                    // - 0.5
                    
                    )
            );


        vcolor = mix(vcolor, rockColor, 0.25*factors[2]*smoothstep(0.5, 0.9, sn-1.0+dtd));
        // vcolor = mix(vcolor, rockColor, 0.25*factors[2]*smoothstep(0.5, 0.9, sn2-1.0+dtd));

        // sn *= 1.0-factors[1]*0.75;

        float off = dtd*sn2*(1.0 + factors[1]*1.0);
        position -= off*normal*0.125;

        // normal -= 0.125*off*sign(normal)/abs(normal.y);
        normal -= 0.5*off*sign(normal)*(1.0-abs(normal.y));
        normal = normalize(normal);

        // float vh = vulpineHash(position.xz, 0.0);
        // float vh = snoise(position*5.0 - 50.0)*0.5 + 0.5;
        

        /* Trying to make rocks */
        // float rockStep = 0.8;
        // float smallRockAlpha = smoothstep(rockStep+0.01, rockStep, sn2);

        // smallRockAlpha += factors[1]*2.0;
        // smallRockAlpha = clamp(smallRockAlpha, 0.0, 1.0);

        // vcolor = mix(rockColor, vcolor, smallRockAlpha);
        // vRoughness = mix(vRoughness, 0.5, vRoughness);

        // position += 0.25*normal*(1.0-smallRockAlpha)*(0.5+0.5*vh);

        // sn2 = sn*4.0;


        // vcolor = hsv2rgb(rgb2hsv(vcolor) * (1.0 + dtd*2.0*sn*2.0*vec3(0.01, -0.1, 0.1)));
        vcolor = hsv2rgb(rgb2hsv(vcolor) * (1.0 + factors[1]*dtd*sn2*2.0*vec3(0.01, -0.1, -0.1)));
    }

    
    // vcolor = grassyness.rrr;

    // position = vec3(0);
    // position -= normal*0.5;

    position.z -= 0.5;
    position.x -= 0.5;

    // #ifdef SHOW_WORLD_REGIONS_HELPER
    if(editorActive != 0)
    {        
        if(editoreditorTextureView != 0)
        {

            if(target > 0)
            /* Grayscale Texture View */
            {
                vcolor = texture(bEditorTexture, uv).rrr;
            }
            else
            /* Climbing Zone Visualisation  */ 
            {
                vRoughness = 1;
                // vMetalness = 0;

                // normal = normalize(normal);
                // vcolor = normal*.5 + .5;
                float angle = degrees(acos(originalNormal.y));

                float lowAngle = 3.0;
                float midAngle = 10.0;
                float highAngle = 15.0;
                float limitAngle = 20.0;

                // vcolor = vec3(0, 0, 1);
                // vcolor = vec3(0);
                // vcolor = mix(vcolor, vec3(0.1), linearstep(50.0, 0.0, angle));
                // vcolor = mix(vcolor, vec3(0, 1, 1), linearstep(lowAngle, midAngle, angle));
                // vcolor = mix(vcolor, vec3(0, 1, 0), linearstep(midAngle, highAngle, angle));
                // vcolor = mix(vcolor, vec3(0), linearstep(highAngle, limitAngle, angle));

                if(normal.y < 1.)
                {
                    vec2 slopeDir = normalize(normal.xz);
                    float bias = 0.25/4096.0;

                    float maxIt = 16.;
                    float size = 2.0/4096.f;

                    float h = texture(bHeight, uv).r*512.f;


                    float endFlatness = 0.;
                    float beginFlatness = 0.;

                    float endLast = h;
                    float beginLast = h;

                    float minH = h;
                    float maxH = h;

                    for(float i = maxIt; i > 0; i--)
                    {
                        float a = size*i/maxIt;

                        float he = texture(bHeight, uv - slopeDir*a).r*512.f;
                        float hb = texture(bHeight, uv + slopeDir*a).r*512.f;

                        if(distance(he, endLast) < 0.05)
                        {
                            endFlatness = 1.0;

                            // minH = min(he, minH);
                            // maxH = max(he, maxH);
                        }

                        if(distance(hb, beginLast) < 0.05)
                        {
                            beginFlatness = 1.0;

                            // minH = min(hb, minH);
                            // maxH = max(hb, maxH);
                        } 

                        minH = min(hb, min(he, minH));
                        maxH = max(hb, max(he, maxH));

                        endLast = he;
                        beginLast = hb;

                    }

                    float climbable = 1.0;

                    climbable = beginFlatness*endFlatness;

                    climbable *= step(normal.y, 0.9);

                    climbable *= step(maxH-minH, 5.0);

                    vec3 climbColor = hsv2rgb(vec3(
                        smoothstep(5.0, 0.5, maxH-minH)*0.35,
                        1.0, 1.0
                    ));

                    vcolor = vec3(0);
                    vcolor = mix(vcolor, climbColor, climbable);


                    vec3 slopeColor = hsv2rgb(vec3(
                        0.35 + 0.3*linearstep(0.8, 1.0, normal.y),
                        1.0, 1.0
                    ));

                    vcolor = mix(vcolor, slopeColor, step(0.8, normal.y));
                    // vcolor = mix(vcolor, vec3(0, 0.5, 0.25), step(0.8, normal.y));

                    // float lowLast = 0;
                    // float highLast = 0;


                    // // for(float i = ; i <= maxIt; i++)
                    // for(float i = maxIt; i > 0; i--)
                    // {
                    //     float a = size*i/maxIt;

                    //     float hLow = texture(bHeight, uv - slopeDir*a).r*512.f;
                    //     float hHigh = texture(bHeight, uv + slopeDir*a).r*512.f;

                    //     if(abs(lowLast - hLow) > 0.1)
                    //         lowLast = hLow;

                    //     if(abs(highLast - hHigh) > 0.5)
                    //         highLast = hHigh;
                    // }

                    // vcolor = abs(lowLast-h).rrr*0.25 * step(0., lowLast);

                    // float maxIt = 8.;
                    // float d = 0.f;

                    // for(float i = 1.0; i < maxIt; i++)
                    // {
                    //     float h1 = texture(bHeight, uv + slopeDir*bias*i).r;
                    //     float h2 = texture(bHeight, uv - slopeDir*bias*i).r;
                    //     float d2 = abs(h1-h2)*512.f;

                    //     if(distance(d, d2) < 0.1/512.f)
                    //         break;
                        
                    //     d = d2;
                    // }

                    // vec3 climbColor = vcolor;

                    // climbColor = mix(climbColor, vec3(1, 1, 0), cubicstep(0.5, 1., d));
                    // climbColor = mix(climbColor, vec3(1, 0.5, 0), cubicstep(1., 2., d));
                    // climbColor = mix(climbColor, vec3(1, 0, 0), cubicstep(2., 3., d));
                    // climbColor = mix(climbColor, vcolor, cubicstep(3., 3.25, d));

                    // climbColor = mix(climbColor, vcolor, linearstep(0.91, 0.92 , normal.y));

                    // vcolor = climbColor;
                }
            }
        }

        /*
            Brush View 
        */
        float d = distance(vec2(position.x, position.z),vec2(editorBrushPos.x, editorBrushPos.z))/editorBrushRange;
        d = smoothstep(1., editorBrushIntensity*0.99, d);
        vcolor = mix(vcolor, editorBrushColor, clamp(d*editorBrushForce, 0.f ,1.f));
        // vEmmisive = d;
    }

    // vcolor = abs(normal);

    // #endif

    #ifdef USING_LAYERED_RENDERING
    gl_Position = vec4(position, 1.0);
    #else
    gl_Position = _cameraMatrix * vec4(position, 1.0);
    #endif
}
	
