#ifndef FUNCTIONS_HASH_GLSL
#define FUNCTIONS_HASH_GLSL

 #include Constants 

/* ###===== Vulpine Hash =====###
*
*   This is a hash function made to be :
*       - Very fast
*       - Seadable 
*       - Without any sine or int operations/conversion
*       - No artifacts when analyzed in rounded coordinates
*
*   Known limitation are :
*       - Defined only in the range ~[-10⁷, +10⁷] with 32 bit float precision
*       - Only as-fast as Fi-hash on a rtx 3070
*/
    float vulpineHash(vec2 uv, float seed)
    {
        uv = PI*50.0*fract(uv*E + 0.5) + uv*0.00007;    
        return fract(
                (uv.x * uv.x * 0.001 * SQR2)
                -
                (uv.x * uv.y * uv.y * 0.001 * (SQR3 + seed))
        );
    }

    float vulpineHash3D(vec3 uv, float seed)
    {
        return vulpineHash(uv.xy + uv.zy + uv.xz, seed);
    }

    float vulpineHash2to1(vec2 uv, float seed)
    {
        return vulpineHash(uv, seed+SQR2);
    }

    vec2 vulpineHash2to2(vec2 uv, float seed)
    {
        return vec2(
            vulpineHash(uv, seed),
            vulpineHash(uv, seed-PHI)
        );
    }

    vec3 vulpineHash2to3(vec2 uv, float seed)
    {
        return vec3(
            vulpineHash(uv, seed),
            vulpineHash(uv, seed-PHI),
            vulpineHash(uv, seed-E)
        );
    }

    vec4 vulpineHash2to4(vec2 uv, float seed)
    {
        return vec4(
            vulpineHash(uv, seed),
            vulpineHash(uv, seed-PHI),
            vulpineHash(uv, seed-E),
            vulpineHash(uv, seed-SQR2)
        );
    }

    float vulpineHash3to1(vec3 uv, float seed)
    {
        return vulpineHash3D(uv, seed+SQR2);
    }

    vec2 vulpineHash3to2(vec3 uv, float seed)
    {
        return vec2(
            vulpineHash3D(uv, seed),
            vulpineHash3D(uv, seed-PHI)
        );
    }

    vec3 vulpineHash3to3(vec3 uv, float seed)
    {
        return vec3(
            vulpineHash3D(uv, seed),
            vulpineHash3D(uv, seed-PHI),
            vulpineHash3D(uv, seed-E)
        );
    }

    vec4 vulpineHash3to4(vec3 uv, float seed)
    {
        return vec4(
            vulpineHash3D(uv, seed),
            vulpineHash3D(uv, seed-PHI),
            vulpineHash3D(uv, seed-E),
            vulpineHash3D(uv, seed-SQR2)
        );
    }

/*
    Source : https://www.shadertoy.com/view/43jSRR
    On my rtx3070, as fast as vulpineHash, but not seedable
    Infinite range
*/
float FiHash(vec2 p) {
    uvec2 u = floatBitsToUint(p * vec2(141421356, 2718281828));
    return float((u.x ^ u.y) * 3141592653u) / float(~0u);
}

#endif