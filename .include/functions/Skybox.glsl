#ifndef FNCT_SKYBOX_GLSL
#define FNCT_SKYBOX_GLSL

#ifdef CUBEMAP_SKYBOX
    layout (binding = 4) uniform samplerCube bSkyTexture; 
#else
    layout (binding = 4) uniform sampler2D bSkyTexture;
#endif

layout (location = 17) uniform vec3 sunDir;
// layout (location = 22) uniform vec3 planetRot;
layout (location = 18) uniform vec3 moonPos;
layout (location = 19) uniform vec3 planetPos;
// layout (location = 25) uniform vec3 moonRot;
layout (location = 20) uniform mat3 tangentSpaceMatrix;

/***
* Function for generating a stary sky with voronoi gradientNoise
***/
vec3 getStars(vec3 viewDir, float starSize, float starDensity, float maxSaturation)
{
    /*** Get star factor with voronoi gradientNoise ***/
    vec3 cell_center;
    vec3 voronoi = voronoi3d(viewDir*starDensity, cell_center);
    float starFactor = 1. - smoothstep(0.0, starSize, voronoi.x);

    /*** Each unique star get a random hue and saturation ***/
    vec3 col = hsv2rgb(vec3(rand3to2(cell_center) * vec2(1.0, maxSaturation), 1.0));

    return col * starFactor;
}


#define IN_STEPS 64
// at least 2 steps (or we get very wrong results) but 3 is better
#define OUT_STEPS 2


// Constants from https://www.shadertoy.com/view/wlBXWK
#define PLANET_RADIUS 6371e3 /* radius of the planet */
#define ATMOS_RADIUS 6471e3 /* radius of the atmosphere */

#define RAY_BETA vec3(5.5e-6, 13.0e-6, 22.4e-6) /* rayleigh, affects the color of the sky */
#define MIE_BETA vec3(21e-6) /* mie, affects the color of the blob around the sun */
#define AMBIENT_BETA vec3(0.0) /* ambient, affects the scattering color when there is no lighting from the sun */
#define ABSORPTION_BETA vec3(2.04e-5, 4.97e-5, 1.95e-6) /* what color gets absorbed by the atmosphere (Due to things like ozone) */
#define G 0.995 /* mie scattering direction, or how big the blob around the sun is */

#define HEIGHT_RAY 8e3 /* rayleigh height */
#define HEIGHT_MIE 0.3e3 /* and mie */
#define HEIGHT_ABSORPTION 30e3 /* at what height the absorption is at it's maximum */
#define ABSORPTION_FALLOFF 8e3 /* how much the absorption decreases the further away it gets from the maximum height */



// heavily inspired by https://www.shadertoy.com/view/wlBXWK
vec3 atmosphericScattering(
    vec3 origin,
    vec3 viewDir,
    vec3 lightDir,
    vec3 sunIntensity,
    vec3 sceneColor,
    float maxDist,
    out float brightness
)
{
    float a = dot(viewDir, viewDir);
    float b = 2.0 * dot(viewDir, origin);
    float c = dot(origin, origin) - (ATMOS_RADIUS * ATMOS_RADIUS);
    float d = (b * b) - 4.0 * a * c;

    if (d < 0.0) return sceneColor;

    vec2 rayLength = vec2(
        max((-b - sqrt(d)) / (2.0 * a), 0.0),
        min((-b + sqrt(d)) / (2.0 * a), maxDist)
    );

    if (rayLength.x > rayLength.y) return sceneColor;

    

    float stepSizeIn = (rayLength.y - rayLength.x) / float(IN_STEPS);

    float rayPosIn = rayLength.x + stepSizeIn * 0.5;

    vec3 totalRay = vec3(0.0);
    vec3 totalMie = vec3(0.0);

    vec3 opticalDepthIn = vec3(0.0);

    vec2 scaleHeight = vec2(HEIGHT_RAY, HEIGHT_MIE);

    float mu = dot(viewDir, lightDir);
    float mumu = mu * mu;
    float gg = G * G;
    float phaseRay = 3.0 / (50.2654824574 /* (16 * pi) */) * (1.0 + mumu);
    float phaseMie = 3.0 / (25.1327412287 /* (8 * pi) */) * ((1.0 - gg) * (mumu + 1.0)) / (pow(1.0 + gg - 2.0 * mu * G, 1.5) * (2.0 + gg));


    for (int i = 0; i < IN_STEPS; i++)
    {
        vec3 p = origin + viewDir * viewDir * rayPosIn;
        float h = length(p) - PLANET_RADIUS;

        vec3 density = vec3(exp(-h / scaleHeight), 0.0);

        float denom = (HEIGHT_ABSORPTION - h) / ABSORPTION_FALLOFF;
        density.z = (1.0 / (denom * denom + 1.0)) * density.x;

        density *= stepSizeIn;

        opticalDepthIn += density;

        float a = dot(lightDir, lightDir);
        float b = 2.0 * dot(lightDir, p);
        float c = dot(p, p) - (ATMOS_RADIUS * ATMOS_RADIUS);
        float d = (b * b) - 4.0 * a * c;

        float stepSizeOut = (-b + sqrt(d)) / (2.0 * a * float(OUT_STEPS));

        float rayPosOut = stepSizeOut * 0.5;

        vec3 opticalDepthOut = vec3(0.0);
        for (int j = 0; j < OUT_STEPS; j++)
        {
            vec3 pOut = p + lightDir * rayPosOut;
            float hOut = length(pOut) - PLANET_RADIUS;
            
            vec3 densityOut = vec3(exp(-hOut / scaleHeight), 0.0);
            float denomOut = (HEIGHT_ABSORPTION - hOut) / ABSORPTION_FALLOFF;
            densityOut.z = (1.0 / (denomOut * denomOut + 1.0)) * densityOut.x;

            densityOut *= stepSizeOut;

            opticalDepthOut += densityOut;

            rayPosOut += stepSizeOut;
        }
        
        vec3 attenuation = exp(-RAY_BETA * (opticalDepthIn.x + opticalDepthOut.x) - 
                                MIE_BETA * (opticalDepthIn.y + opticalDepthOut.y) - 
                                ABSORPTION_BETA * (opticalDepthIn.z + opticalDepthOut.z));
        
        totalRay += max(density.x * attenuation, 0.0);
        totalMie += max(density.y * attenuation, 0.0);

        rayPosIn += stepSizeIn;
    }

    vec3 opacity = exp(-(MIE_BETA * opticalDepthIn.y + 
                         RAY_BETA * opticalDepthIn.x + 
                         ABSORPTION_BETA * opticalDepthIn.z));

    vec3 scatteredLight = (
        phaseRay * RAY_BETA * totalRay + 
        phaseMie * MIE_BETA * totalMie + 
        opticalDepthIn.x * AMBIENT_BETA
        );

    brightness = dot(scatteredLight, vec3(0.2126, 0.7152, 0.0722)); 

    return scatteredLight * sunIntensity + sceneColor * opacity;
}

vec3 rotate(vec3 v, float a, vec3 axis)
{
    float s = sin(a);
    float c = cos(a);
    float oc = 1.0 - c;

    mat3 rot = mat3(
        oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s,
        oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s,
        oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c
    );

    return rot * v;
}

struct rayTraceOut {
    float t;
    vec3 intersectPoint;
    vec3 normal;
    vec2 uv;
};

rayTraceOut sphereIntersect(vec3 origin, vec3 direction, vec3 center, float radius)
{
    vec3 v = origin - center;

    float a = dot(direction, direction);
    float b = 2.0 * dot(direction, v);
    float c = dot(v, v) - radius * radius;

    rayTraceOut empty;
    empty.t = -1.0;
    float delta = b * b - 4.0 * a * c;
    if (delta < 0.0)
    {
        return empty;
        // return vec3(0);
    }

    float t1 = (-b + sqrt(delta)) / (2.0 * a);
    float t2 = (-b - sqrt(delta)) / (2.0 * a);

    if (t1 < 0.0 && t2 < 0.0)
    {
        return empty;
        // return vec3(0);
    }

    float t;
    
    if (t1 < 0.0001)
    {
        t = t2;
    }
    else if (t2 < 0.0001)
    {
        t = t1;
    }
    else
    {
        t = min(t1, t2);
    }

    rayTraceOut rslt;
    rslt.t = t;
    rslt.intersectPoint = origin + direction * t;
    rslt.normal = normalize(rslt.intersectPoint - center);
    
    // compute uv
    vec3 n = rslt.normal;
    float phi = atan(n.z, n.x);
    float theta = acos(n.y);
    rslt.uv = vec2(1.0 - (phi + 3.14159265359) / (2.0 * 3.14159265359), theta / 3.14159265359);


    return rslt;
    // return origin + direction * t;
}

#define MOON_RADIUS 1.0*12737.1e3
#define MOON_DISTANCE 384400e3

void getMoonColor(vec3 origin, vec3 direction, inout vec3 color, float opacity)
{
    vec3 sunPos = -planetPos.xyz;

    vec3 tangentSpaceDir = tangentSpaceMatrix * direction.xyz;


    rayTraceOut moonIntersect = sphereIntersect(origin, tangentSpaceDir, moonPos, MOON_RADIUS);

    if (moonIntersect.t > 0.0)
    {
        // shading
        vec3 moonNormal = moonIntersect.normal;
        vec3 moonToSun = normalize(sunPos - moonPos);
        float moonAngle = dot(moonToSun, moonNormal);


        float moonIntensity = max(moonAngle, 0.0);
        vec3 colorBlack = vec3(0.0);

        float n1 = gradientNoise((moonIntersect.uv + vec2(-.2, .10)) * vec2(5.0, 4.0)) * 1.4;
        float n2 = gradientNoise((moonIntersect.uv + vec2(-.7, -.9)) * vec2(5., 4.)) * -0.6;
        float n3 = gradientNoise((moonIntersect.uv + vec2(.1, .5)) * vec2(10.0, 5.0)) * 0.2;
        float n4 = gradientNoise((moonIntersect.uv.yx + vec2(.2, -.9)) * vec2(5.0, 20.0)) * -0.1;

        float n = min(n1 + n2 + n3 + n4, 1.0);

        // float n = rand3to1(vec3(moonIntersect.uv, 1));

        vec3 colMoon = vec3(n);

        // colMoon = vec3(moonIntersect.uv, 1.0);

        vec3 moonColor = mix(colorBlack, colMoon, moonIntensity)*vec3(1.0, 0.9, 0.8)*1.5;
        color = mix(color, moonColor, max(opacity, 0.15));
    }

}

void getSkyColors(
    vec3 dir, inout vec3 color, inout vec3 _emmisive
)
{
    vec3 rayDir = dir;
    vec3 planetPos = vec3(0, PLANET_RADIUS + 100, 0);

    const vec3 sunColor = vec3(1.0, 0.95, 0.85);
    vec3 lightIntensity = sunColor * 10.0;
    
    vec3 sceneColor = vec3(0);
    
    float brightness;
    vec3 rayleighScatteringColor = atmosphericScattering(planetPos, rayDir, sunDir, lightIntensity, sceneColor, 3.0 * ATMOS_RADIUS, brightness);

    brightness *= 255.0;
    brightness = clamp(brightness, 0.0, 1.0);

    vec3 starsColor = getStars(rayDir, 0.1, 40, 0.5);
    vec3 finalColor = mix(rayleighScatteringColor, starsColor + rayleighScatteringColor, 1.0 - brightness);

    getMoonColor(planetPos, rayDir, finalColor, 1.0 - brightness);

    color = finalColor;

    /**** Sun emissive ****/
    _emmisive = 0.025 * vec3(color * smoothstep(0.9, 0.9995, dot(rayDir, sunDir)));

    /**** Moon & stars emissive ****/
    _emmisive += 0.2 * smoothstep(-0.2, -0.3, sunDir.y) * (color + starsColor*2);
}

vec3 getAtmopshereColor(
    vec3 dir
)
{
    vec3 rayDir = dir;
    vec3 planetPos = vec3(0, PLANET_RADIUS + 100, 0);

    const vec3 sunColor = vec3(1.0, 0.95, 0.85);
    vec3 lightIntensity = sunColor * 10.0;
    
    vec3 sceneColor = vec3(0);
    
    float brightness;
    vec3 rayleighScatteringColor = atmosphericScattering(planetPos, rayDir, sunDir, lightIntensity, sceneColor, 3.0 * ATMOS_RADIUS, brightness);

    return rayleighScatteringColor;
}

vec3 getSkyColor(vec3 v)
{
    // return v;

    vec3 color;
    vec3 _emmisive;
    getSkyColors(v, color, _emmisive);

    return color;

    // vec3 c = texture(bSkyTexture, uv).rgb;

    // float exposure = 0.5;
    // float gamma = 2.0;

    // // float brightMax = 0.1;
    // // exposure = exposure * (exposure/brightMax + 1.0) / (exposure + 1.0);
    
    // // c = vec3(1.0) - exp(-c*exposure);

    // // c *= pow(2.0, exposure);
    // // c = toneMapReinhard(c, exposure, 0.1);

    // // c *= exposure;

    // // c = pow(c, vec3(1.0/gamma));

    // return c;
}

#endif
