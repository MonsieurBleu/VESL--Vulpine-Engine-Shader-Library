#version 460

#define USING_VERTEX_TEXTURE_UV
#define USING_LOD_TESSELATION

#include Base3D 
#include Model3D 

#ifdef ARB_BINDLESS_TEXTURE
    layout (location = 22, bindless_sampler) uniform sampler2D bHeight;
#else
    layout (binding = 2) uniform sampler2D bHeight;
#endif


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

void main()
{
    // ----------------------------------------------------------------------
    // pass attributes through
    gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;
    patchUv[gl_InvocationID] = vertexUv[gl_InvocationID];
    patchPosition[gl_InvocationID] = vertexPos[gl_InvocationID]; 
    patchNormal[gl_InvocationID] = vertexNormal[gl_InvocationID]; 

    // ----------------------------------------------------------------------
    // invocation zero controls tessellation levels for the entire patch


    // const float MIN_DISTANCE = 32;
    // const float MAX_DISTANCE = 1024;

    // float dist = 1. - (distance(vec3(_modelMatrix * vec4(patchPosition[0], 1.0)), _cameraPosition) - MIN_DISTANCE)/(MAX_DISTANCE-MIN_DISTANCE);

    // dist = max(dist, 0.);


    // float clampSize = 0.25;
    // dist = round(dist/clampSize)*clampSize;

    // dist = pow(dist, 4.0);

    // gl_TessLevelOuter[gl_InvocationID] = 1 + (dist*24);

    // if (gl_InvocationID == 0)
    // {
        
    //     gl_TessLevelInner[0] = gl_TessLevelOuter[gl_InvocationID];
    //     // gl_TessLevelInner[1] = gl_TessLevelOuter[gl_InvocationID];
    // }


    if(gl_InvocationID == 0)
    {

        const float MIN_DISTANCE = 0;
        const float MAX_DISTANCE = 1024;

        float worldDist00 = distance(vec3(_modelMatrix * vec4(patchPosition[0], 1.0)).xz, _cameraPosition.xz);
        float worldDist01 = distance(vec3(_modelMatrix * vec4(patchPosition[1], 1.0)).xz, _cameraPosition.xz);
        float worldDist10 = distance(vec3(_modelMatrix * vec4(patchPosition[2], 1.0)).xz, _cameraPosition.xz);

        vec3 depths = vec3(worldDist00, worldDist01, worldDist10);
        vec3 distances = clamp(1.-(depths-MIN_DISTANCE)/(MAX_DISTANCE-MIN_DISTANCE), 0.0, 1.0);
        
        vec3 tessDist = vec3( min(distances[1], distances[2]), min(distances[2], distances[0]), min(distances[0], distances[1]));

        
        float snapVal = 4;
        tessDist = pow(tessDist, vec3(2.0));
        tessDist = ceil(tessDist*snapVal)/snapVal;
        tessDist = pow(tessDist, vec3(4.0));

        // tessDist = vec3(0);

        for(int i = 0; i < 3; i++)
        {
            int j = (i+1)%3;
            int k = (i+2)%3;

            if(i == 0){j = 1; k = 2;}
            if(i == 1){j = 0; k = 2;}
            if(i == 2){j = 1; k = 0;}

            float diffSum = 0.;
            float lastH = texture(bHeight, patchUv[j]).r;

            for(float a = 0.; a <= 1.01f; a += 0.1)
            {
                float h = texture(bHeight, mix(patchUv[j], patchUv[k], a)).r;
                diffSum += distance(h, lastH);
                lastH = h;
            }
            
            /* Slope Ajusted tesselation factor */
            tessDist[i] *= 0.5 + 0.5*smoothstep(0., 0.1, diffSum);
            tessDist[i] = clamp(tessDist[i] + diffSum*0.8, 0., 1.);

            gl_TessLevelOuter[i] = max(1, round(tessDist[i]*48));
        }
        
        gl_TessLevelInner[0] = min(gl_TessLevelOuter[0], min(gl_TessLevelOuter[1], gl_TessLevelOuter[2]));
    }
}