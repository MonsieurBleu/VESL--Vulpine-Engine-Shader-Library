#version 460

#include SceneDefines3D.glsl

#ifdef ARB_BINDLESS_TEXTURE
#extension GL_ARB_bindless_texture : require
#endif

#define USING_VERTEX_TEXTURE_UV

#include uniform/Base3D.glsl
#include uniform/Model3D.glsl
#include uniform/Ligths.glsl

#ifdef ARB_BINDLESS_TEXTURE
layout (location = 20, bindless_sampler) uniform sampler2D bTexture;
#else
layout (binding = 0) uniform sampler2D bTexture;
#endif

layout (location = 21) uniform vec3 sunDir;
layout (location = 22) uniform vec3 planetRot;
layout (location = 23) uniform vec3 moonPos;
layout (location = 24) uniform vec3 planetPos;
layout (location = 25) uniform vec3 moonRot;
layout (location = 26) uniform mat3 tangentSpaceMatrix;

#include globals/Fragment3DInputs.glsl
#include globals/Fragment3DOutputs.glsl

#include functions/standardMaterial.glsl
#include functions/Skybox.glsl

in vec3 viewPos;

float gamma = 1.8;
float exposure = 1.0;


const mat2 myt = mat2(.12121212, .13131313, -.13131313, .12121212);
const vec2 mys = vec2(1e4, 1e6);

vec2 rhash(vec2 uv) {
  uv *= myt;
  uv *= mys;
  return fract(fract(uv / mys) * uv);
}

vec3 hash(vec3 p) {
  return fract(sin(vec3(dot(p, vec3(1.0, 57.0, 113.0)),
                        dot(p, vec3(57.0, 113.0, 1.0)),
                        dot(p, vec3(113.0, 1.0, 57.0)))) *
               43758.5453);
}

float rand(float n){return fract(sin(n) * 43758.5453123);}

float rand(vec2 n) { 
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

vec2 voronoi2d(const in vec2 point) {
  vec2 p = floor(point);
  vec2 f = fract(point);
  float res = 0.0;
  
  float minDist = 1.0;
  float v = 0.0;
  
  for (int j = -1; j <= 1; j++) {
    for (int i = -1; i <= 1; i++) {
      vec2 b = vec2(i, j);
      vec2 r = vec2(b) - f + rhash(p + b);
      float dist = dot(r, r);
      res += 1. / pow(dist, 8.);
      
      if (dist < minDist) {
          minDist = dist;
          v = rand(p + b + rhash(p + b) - 0.5);
      }
    }
  }
  float gradient = pow(1. / res, 0.0625);
  
  return vec2(v, gradient);
}

vec3 rgb(vec3 c) {
    return c / 255.0;
}

vec3 rgb(float r, float g, float b) {
    return vec3(r, g, b) / 255.0;
}

// generate star function
vec3 getStars(vec3 viewDir, float scale, float starSize, float starDensity, float maxSaturation, out float brightness)
{
    // Convert viewDir to spherical coordinates
    float longitude = atan(viewDir.y, viewDir.x);
    float latitude = acos(viewDir.z);
    
    // Use spherical coordinates as the basis for Voronoi hashing
    vec2 sphericalCoord = vec2(longitude, latitude) * scale;
    
    // Get the Voronoi cell hash based on spherical coordinates
    vec2 voronoi = voronoi2d(sphericalCoord);
    float cell = voronoi.x;
    float gradient = voronoi.y;
    
    // Calculate the star factor (brightness) based on cell center proximity
    float cellGradient = clamp((1.0 - gradient), 0.0, 1.0);
    float threshold = 1.0 - starSize + rand(cell) * 0.01;
    float starFactor = mix(0.0, 1.0, 
        smoothstep(threshold, 1.0, cellGradient) * step(1.0 - starDensity, cell)
    );
    
    // Determine star color using unique hue and saturation per cell
    float h = rand(1.0 - cell);
    float s = maxSaturation * rand(h);
    vec3 col = hsv2rgb(vec3(h, s, 1.0));
    
    // Apply star brightness factor to get the final star color
    col *= starFactor;

    brightness = 1.0 - clamp(cell * 200, 0.00, 1.0);

    return col;
}


#define IN_STEPS 16
// at least 2 steps (or we get very wrong results) but 3 is better
#define OUT_STEPS 2


// Constants from https://www.shadertoy.com/view/wlBXWK
#define PLANET_RADIUS 6371e3 /* radius of the planet */
#define ATMOS_RADIUS 6471e3 /* radius of the atmosphere */

#define RAY_BETA vec3(5.5e-6, 13.0e-6, 22.4e-6) /* rayleigh, affects the color of the sky */
#define MIE_BETA vec3(21e-6) /* mie, affects the color of the blob around the sun */
#define AMBIENT_BETA vec3(0.0) /* ambient, affects the scattering color when there is no lighting from the sun */
#define ABSORPTION_BETA vec3(2.04e-5, 4.97e-5, 1.95e-6) /* what color gets absorbed by the atmosphere (Due to things like ozone) */
#define G 0.97 /* mie scattering direction, or how big the blob around the sun is */

#define HEIGHT_RAY 8e3 /* rayleigh height */
#define HEIGHT_MIE 1.2e3 /* and mie */
#define HEIGHT_ABSORPTION 30e3 /* at what height the absorption is at it's maximum */
#define ABSORPTION_FALLOFF 4e3 /* how much the absorption decreases the further away it gets from the maximum height */



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

// should probably get some other coherent noise function
vec2 random2(vec2 st){
    st = vec2( dot(st,vec2(127.1,311.7)),
              dot(st,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(st)*43758.5453123);
}

// Gradient Noise by Inigo Quilez - iq/2013
// https://www.shadertoy.com/view/XdXGW8
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    vec2 u = f*f*(3.0-2.0*f);

    return (mix( mix( dot( random2(i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ),
                     dot( random2(i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( random2(i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ),
                     dot( random2(i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y)) * .5 + .5;
}

#define MOON_RADIUS 12737.1e3
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

        float n1 = noise((moonIntersect.uv + vec2(-.2, .10)) * vec2(5.0, 4.0)) * 1.4;
        float n2 = noise((moonIntersect.uv + vec2(-.7, -.9)) * vec2(5., 4.)) * -0.6;
        float n3 = noise((moonIntersect.uv + vec2(.1, .5)) * vec2(10.0, 5.0)) * 0.2;
        float n4 = noise((moonIntersect.uv.yx + vec2(.2, -.9)) * vec2(5.0, 20.0)) * -0.1;

        float n = min(n1 + n2 + n3 + n4, 1.0);
        vec3 colMoon = vec3(n);

        // colMoon = vec3(moonIntersect.uv, 1.0);

        vec3 moonColor = mix(colorBlack, colMoon, moonIntensity);
        color = mix(color, moonColor, max(opacity, 0.15));
    }
}

void main()
{
    // color = getSkyColor(uv);
    // color = texture(bTexture, uv).rgb;

    // color = pow(vec3(1.0) - exp(-color*exposure), vec3(1.0/gamma));

    vec3 planetPos = vec3(0, PLANET_RADIUS + 100, 0);

    
    vec2 ndc = (gl_FragCoord.xy / _iResolution) * 2.0 - 1.0;
    // ndc.y = -ndc.y;

    vec4 rayClip = vec4(ndc, 1.0, 1.0);
    mat4 cameraProjectionMatrixInverse = inverse(_cameraProjectionMatrix);
    vec4 rayView = cameraProjectionMatrixInverse * rayClip;
    vec3 rayDirCamSpace = normalize(rayView.xyz / rayView.w);

    vec3 rayDir = normalize((inverse(_cameraViewMatrix) * vec4(rayDirCamSpace, 0.0)).xyz);

    vec3 sunColor = vec3(1.0, 0.95, 0.85);
    vec3 lightIntensity = sunColor * 40.0;
    
    
    vec3 starsDir = rayDir;

    // rotate the stars direction based on the planet rotation
    // very bad way to do this >:(
    // starsDir = rotate(starsDir, planetRot.x, vec3(1, 0, 0));

    float starBrightness;
    
    vec3 sceneColor = vec3(0);
    
    float brightness;
    vec3 rayleighScatteringColor = atmosphericScattering(planetPos, rayDir, sunDir, lightIntensity, sceneColor, 3.0 * ATMOS_RADIUS, brightness);

    brightness *= 255.0;
    brightness = clamp(brightness, 0.0, 1.0);

    vec3 starsColor = getStars(starsDir, 40.0, 0.05, 0.5, 0.3, starBrightness);
    vec3 finalColor = mix(rayleighScatteringColor, starsColor + rayleighScatteringColor, 1.0 - brightness);

    finalColor = 1.0 - exp(-finalColor);

    getMoonColor(planetPos, rayDir, finalColor, 1.0 - brightness);

    fragColor.rgb = finalColor;
    // fragColor.rgb = vec3(gl_FragCoord.xy / _iResolution, 0.0);
    // fragColor.rgb = viewDir;
    fragColor.a = 1.0;
    // fragEmmisive = getStandardEmmisive(fragColor.rgb, ambientLight);

    // get ray angle distance to sun
    float angle = dot(rayDir, sunDir);
    if (angle > 0.999)
    {
        // fragColor.rgb = vec3(1, 0, 1);
    }
    

    // fragEmmisive = 0.65*fragColor.rgb*(rgb2v(fragColor.rgb) - ambientLight);

    float v = rgb2v(fragColor.rgb);


    // fragEmmisive = fragColor.rgb*pow(v, 15.0);

    fragEmmisive =  vec3(smoothstep(0.996, 0.9995, angle));

    // fragColor.rgb = vec3(uv, 1.0);
    // fragColor.rgb = vec3(uv.x-mod(uv.x, 0.1), 0.1, 0.0);
    // fragColor.rgb = vec3(0.1, uv.y-mod(uv.y, 0.1), 0.0);

    fragNormal = vec3(1);
}
