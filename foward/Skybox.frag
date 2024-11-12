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
vec3 getStars(vec3 viewDir, float scale, float starSize, float starDensity, float maxSaturation)
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

    return col;
}

#define OUT_STEPS 8
#define IN_STEPS 32


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
    float maxDist
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
        
        totalRay += density.x * attenuation;
        totalMie += density.y * attenuation;

        rayPosIn += stepSizeIn;
    }

    vec3 opacity = exp(-(MIE_BETA * opticalDepthIn.y + 
                         RAY_BETA * opticalDepthIn.x + 
                         ABSORPTION_BETA * opticalDepthIn.z));

    float brightness = clamp(length(RAY_BETA * totalRay) * 10.0, 0.0, 1.0);

    return (
        phaseRay * RAY_BETA * totalRay + 
        phaseMie * MIE_BETA * totalMie + 
        opticalDepthIn.x * AMBIENT_BETA
        ) * sunIntensity + sceneColor * opacity * (1.0 - brightness);
}

void main()
{
    // color = getSkyColor(uv);
    // color = texture(bTexture, uv).rgb;

    // color = pow(vec3(1.0) - exp(-color*exposure), vec3(1.0/gamma));

    vec3 planetPos = vec3(0, PLANET_RADIUS, 0);
    float sunYaw = radians(-90.0);
    float sunPitch = radians(179.0);

    float d = 9e10;
    vec3 sunPos = vec3(
        sin(sunYaw) * d * cos(sunPitch), 
        sin(sunPitch) * d,  
        cos(sunYaw) * d * cos(sunPitch)
    );
    
    vec2 ndc = (gl_FragCoord.xy / _iResolution) * 2.0 - 1.0;
    // ndc.y = -ndc.y;

    vec4 rayClip = vec4(ndc, 1.0, 1.0);
    mat4 cameraProjectionMatrixInverse = inverse(_cameraProjectionMatrix);
    vec4 rayView = cameraProjectionMatrixInverse * rayClip;
    vec3 rayDirCamSpace = normalize(rayView.xyz / rayView.w);

    vec3 rayDir = normalize((inverse(_cameraViewMatrix) * vec4(rayDirCamSpace, 0.0)).xyz);
    
    vec3 lightDir = normalize(sunPos - planetPos);

    vec3 sunColor = vec3(1.0, 0.95, 0.85);
    vec3 lightIntensity = sunColor * 40.0;
    
    
    vec3 starsColor = getStars(rayDir, 40.0, 0.05, 0.5, 0.3);
    vec3 sceneColor = starsColor;
    
    vec3 rayleighScatteringColor = atmosphericScattering(planetPos, rayDir, lightDir, lightIntensity, sceneColor, 3.0 * ATMOS_RADIUS);
    vec3 finalColor = rayleighScatteringColor;

    finalColor = 1.0 - exp(-finalColor);

    fragColor.rgb = finalColor;
    // fragColor.rgb = vec3(gl_FragCoord.xy / _iResolution, 0.0);
    // fragColor.rgb = viewDir;
    fragColor.a = 1.0;
    // fragEmmisive = getStandardEmmisive(fragColor.rgb, ambientLight);

    // fragEmmisive = 0.65*fragColor.rgb*(rgb2v(fragColor.rgb) - ambientLight);

    float v = rgb2v(fragColor.rgb);
    fragEmmisive = fragColor.rgb*pow(v, 15.0);

    // fragColor.rgb = vec3(uv, 1.0);
    // fragColor.rgb = vec3(uv.x-mod(uv.x, 0.1), 0.1, 0.0);
    // fragColor.rgb = vec3(0.1, uv.y-mod(uv.y, 0.1), 0.0);

    fragNormal = vec3(1);
}
