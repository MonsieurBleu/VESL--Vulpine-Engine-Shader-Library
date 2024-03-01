#version 460

layout (quads, fractional_odd_spacing, ccw) in;

in vec2 patchUv[];

#include globals/Vertex3DOutputs.glsl

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

void main()
{
    // get patch coordinate
    float u = gl_TessCoord.x;
    float v = gl_TessCoord.y;

    // ----------------------------------------------------------------------
    // retrieve control point texture coordinates
    vec2 t00 = patchUv[0];
    vec2 t01 = patchUv[1];
    vec2 t10 = patchUv[2];
    vec2 t11 = patchUv[3];

    // bilinearly interpolate texture coordinate across patch
    vec2 t0 = (t01 - t00) * u + t00;
    vec2 t1 = (t11 - t10) * u + t10;
    uv = (t1 - t0) * v + t0;

    float h = texture(bHeight, uv).r;

    // ----------------------------------------------------------------------
    // retrieve control point position coordinates
    vec3 p00 = gl_in[0].gl_Position;
    vec3 p01 = gl_in[1].gl_Position;
    vec3 p10 = gl_in[2].gl_Position;
    vec3 p11 = gl_in[3].gl_Position;

    // compute patch surface normal
    vec4 uVec = p01 - p00;
    vec4 vVec = p10 - p00;
    normal = normalize(cross(vVec.xyz, uVec.xyz));

    // bilinearly interpolate position coordinate across patch
    vec3 p0 = (p01 - p00) * u + p00;
    vec3 p1 = (p11 - p10) * u + p10;
    vec3 positionInModel = (p1 - p0) * v + p0;

    // displace point along normal
    positionInModel += normal * h;

    // ----------------------------------------------------------------------
    // output patch point position in clip space
    #include code/SetVertex3DOutputs.glsl
    gl_Position = _cameraMatrix * vec4(position, 1.0);
}
	
