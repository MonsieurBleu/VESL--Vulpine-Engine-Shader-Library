layout (binding = 3) uniform sampler2D bTerrainMap;
layout (binding = 5) uniform sampler2D bTerrainCE[4];
layout (binding = 9) uniform sampler2D bTerrainNRM[4];

vec4 getTerrainTexture(vec4 factors, vec2 uv, sampler2D textures[4])
{
    vec4 res = vec4(0.0);
    res = mix(res, texture(textures[2], uv), factors[2]);
    res = mix(res, texture(textures[3], uv), factors[3]);
    res = mix(res, texture(textures[1], uv), factors[1]);
    res = mix(res, texture(textures[0], uv), factors[0]);
    return res;
}

vec4 getTerrainFactorFromState(vec3 tNormal, float tH)
{
    vec4 factors = vec4(0.0);
    const float steep = abs(tNormal.y);
    factors.b = 1.0;
    factors.g = 1.0 - pow(smoothstep(0.0, 0.9, steep), 2.0);
    factors.a = 1.0 - pow(smoothstep(0.6, 1.0, steep), 3.0);
    float snowLevel = 0.65;
    factors.r = smoothstep(snowLevel + 0.05*steep, snowLevel+0.1, tH);
    factors.r = factors.r * (1.0-factors.g);
    return factors;
}
