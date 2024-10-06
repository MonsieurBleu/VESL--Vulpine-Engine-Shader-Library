#version 460

#define USING_VERTEX_TEXTURE_UV
#define USING_LOD_TESSELATION

#include uniform/Base3D.glsl
#include uniform/Model3D.glsl

// specify number of control points per patch output
// this value controls the size of the input and output arrays
layout (vertices=3) out;

// varying input from vertex shader
in vec2 vertexUv[];
in vec3 vertexPos[];
in vec3 vertexNormal[];

// varying output to evaluation shader
out vec2 patchUv[];
out vec3 patchPosition[];
out vec3 patchNormal[];

#ifdef ARB_BINDLESS_TEXTURE
    layout (location = 20, bindless_sampler) uniform sampler2D bColor;
    // layout (location = 21, bindless_sampler) uniform sampler2D bMaterial;
    layout (location = 22, bindless_sampler) uniform sampler2D bHeight;
#else
    layout(binding = 0) uniform sampler2D b_Color;
    layout(binding = 1) uniform sampler2D bMaterial;
    layout(binding = 2) uniform sampler2D bHeight;
#endif

void main()
{
    // ----------------------------------------------------------------------
    // pass attributes through
    gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;
    patchUv[gl_InvocationID] = vertexUv[gl_InvocationID];
    patchPosition[gl_InvocationID] = vertexPos[gl_InvocationID]; 
    patchNormal[gl_InvocationID] = vertexNormal[gl_InvocationID]; 


    // patchPosition[gl_InvocationID] -= vertexPos[0]*0.02;
    // patchPosition[gl_InvocationID] -= vertexPos[1]*0.02;

    // ----------------------------------------------------------------------
    // invocation zero controls tessellation levels for the entire patch
    if (gl_InvocationID == 0)
    {
        const int MIN_TESS_LEVEL = int(lodTessLevelDistance.x);
        const int MAX_TESS_LEVEL = int(lodTessLevelDistance.y);
        
        // const float MIN_DISTANCE = lodTessLevelDistance.z;
        // const float MAX_DISTANCE = lodTessLevelDistance.w;

        const float MIN_DISTANCE = 75;
        const float MAX_DISTANCE = 500;

        float worldDist00 = distance(vec3(_modelMatrix * vec4(patchPosition[0], 1.0)).xz, _cameraPosition.xz);
        float worldDist01 = distance(vec3(_modelMatrix * vec4(patchPosition[1], 1.0)).xz, _cameraPosition.xz);
        float worldDist10 = distance(vec3(_modelMatrix * vec4(patchPosition[2], 1.0)).xz, _cameraPosition.xz);
        
        vec3 depths = abs(vec3(worldDist00, worldDist01, worldDist10));
        vec3 distances = clamp((depths-MIN_DISTANCE)/(MAX_DISTANCE-MIN_DISTANCE), 0.0, 1.0);

        vec3 tessDist = vec3( min(distances[1], distances[2]), min(distances[2], distances[0]), min(distances[0], distances[1]));
        
        tessDist = 1.0 - pow(tessDist, vec3(0.5));

        // tessDist = 1.0/(1.0 - tessDist + 1e-9);

        float snapVal = 3;
        tessDist = ceil(tessDist*snapVal)/snapVal;

        // tessDist = smoothstep(0.0, 1.0, tessDist);

        tessDist = pow(tessDist, vec3(5.0));

        ivec3 tessLevel;
        tessLevel = 1 + ivec3(ceil(tessDist*24.0));

        // for(int i = 0; i < 3; i++)
        //     if(tessDist[i] > 0.999)
        //         tessLevel[i] = MIN_TESS_LEVEL;
        //     else if(tessDist[i] > 0.5)
        //         tessLevel[i] = MAX_TESS_LEVEL/4;
        //     else if(tessDist[i] > 0.1)
        //         tessLevel[i] = MAX_TESS_LEVEL/2 - 1;
        //     else
        //         tessLevel[i] = MAX_TESS_LEVEL;

        // for(int i = 0; i < 3; i++)
        // {
        //     tessLevel[i] = int(round(MIN_TESS_LEVEL + (MAX_TESS_LEVEL-MIN_DISTANCE)*tessDist[i]));
        // }

        // tessLevel = ivec3(MAX_TESS_LEVEL);
        // tessLevel = ivec3((0.5 + 0.5*cos(_iTime))*63.0 + 1);

        
        // float slope = 0.f;
        // for(int i = 0; i < 3; i++)
        // {
        //     float bias = 0.01;
        //     vec2 hUv = patchUv[i]*lodHeightDispFactors.z;

        //     float h1 = texture(bHeight, clamp(hUv, 0.001, 0.999)).r;

        //     float h2 = texture(bHeight, clamp(hUv+vec2(bias, 0), 0.001, 0.999)).r;
        //     float h3 = texture(bHeight, clamp(hUv+vec2(0, bias), 0.001, 0.999)).r;

        //     float h4 = texture(bHeight, clamp(hUv-vec2(bias, 0), 0.001, 0.999)).r;
        //     float h5 = texture(bHeight, clamp(hUv-vec2(0, bias), 0.001, 0.999)).r;

        //     float slopep = max(abs(h1-h2), abs(h1-h3))/bias;
        //     float slopem = max(abs(h1-h4), abs(h1-h5))/bias;

        //     slope = max(slope, max(slopep, slopem));

        //     // tessLevel[i] = 1 + int(max(slopep, slopem)*8.0);
            
        // }

        

        // slope = clamp(slope, 0, 1);
        // slope = pow(slope, 2.0);
        // slope = step(3.0, slope);

        // slope = smoothstep(0.0, 1.0, slope);

        // if(tessLevel[0] <= 2)
        //     tessLevel = tessLevel + ivec3(round(slope*1.0));



        // tessLevel = ivec3(1);

        gl_TessLevelOuter[0] = tessLevel.x;
        gl_TessLevelOuter[1] = tessLevel.y;
        gl_TessLevelOuter[2] = tessLevel.z;

        gl_TessLevelInner[0] = gl_TessLevelOuter[0];

        // gl_TessLevelInner[0] = max(gl_TessLevelOuter[0], gl_TessLevelOuter[1]);
        // gl_TessLevelInner[0] = max(gl_TessLevelInner[0], gl_TessLevelOuter[2]);

        // gl_TessLevelInner[1] = gl_TessLevelOuter[1];
        // gl_TessLevelInner[2] = gl_TessLevelOuter[2];
    }
}