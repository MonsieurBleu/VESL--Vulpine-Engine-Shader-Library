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
    if (gl_InvocationID == 0)
    {
        const int MIN_TESS_LEVEL = int(lodTessLevelDistance.x);
        const int MAX_TESS_LEVEL = int(lodTessLevelDistance.y);
        
        const float MIN_DISTANCE = lodTessLevelDistance.z;
        const float MAX_DISTANCE = lodTessLevelDistance.w;

        float worldDist00 = distance(vec3(_modelMatrix * vec4(patchPosition[0], 1.0)).xz, _cameraPosition.xz);
        float worldDist01 = distance(vec3(_modelMatrix * vec4(patchPosition[1], 1.0)).xz, _cameraPosition.xz);
        float worldDist10 = distance(vec3(_modelMatrix * vec4(patchPosition[2], 1.0)).xz, _cameraPosition.xz);
        
        vec3 depths = abs(vec3(worldDist00, worldDist01, worldDist10));
        vec3 distances = clamp((depths-MIN_DISTANCE)/(MAX_DISTANCE-MIN_DISTANCE), 0.0, 1.0);

        vec3 tessDist = vec3( min(distances[1], distances[2]), min(distances[2], distances[0]), min(distances[0], distances[1]));
        
        tessDist = 1.0 - pow(tessDist, vec3(0.5));
        float snapVal = 3;
        tessDist = ceil(tessDist*snapVal)/snapVal;
        tessDist = pow(tessDist, vec3(5.0));

        ivec3 tessLevel;
        tessLevel = MIN_TESS_LEVEL + ivec3(ceil(tessDist*MAX_TESS_LEVEL));

        gl_TessLevelOuter[0] = tessLevel.x;
        gl_TessLevelOuter[1] = tessLevel.y;
        gl_TessLevelOuter[2] = tessLevel.z;
        gl_TessLevelInner[0] = gl_TessLevelOuter[0];
    }
}