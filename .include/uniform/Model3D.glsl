layout (location = 16) uniform mat4 _modelMatrix;

#ifdef USING_LOD_TESSELATION

    layout (location = 10) uniform vec4 lodHeigtTextureRange;
    layout (location = 11) uniform vec4 lodHeightDispFactors;
    layout (location = 12) uniform vec4 lodTessLevelDistance;

#endif