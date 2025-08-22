#version 460

 #include Base2D 
 #include Model3D 
#include HSV
 #include Constants 

layout(location = 0) out vec4 fragColor;

in vec2 uv;
in vec4 color;
in flat int type;
in float aspectRatio;
in float scale;

float SMOOTHSTEP_BORDER = 0.01;
// const float SMOOTHSTEP_BORDER_SQUARED = SMOOTHSTEP_BORDER*SMOOTHSTEP_BORDER;

float borderSize = 0.05;

vec2 arCorrection = vec2(0);

#define SKYBOX_REFLECTION
#define SUN_DIR_NON_UNIFORM
#include Skybox 


float drawCircle(vec2 inUv) {
    float l = length(inUv);
    fragColor.a *= smoothstep(1.0, 1.0 - SMOOTHSTEP_BORDER, l);
    return l;
}

float drawSquareRounded(float cornerSize, vec2 inUv) {
    inUv = abs(inUv * arCorrection);
    vec2 c = arCorrection - cornerSize;

    vec2 cUv = max(inUv, c) - c;
    float inBorder = 1.0 - step(cUv.x, 0.) * step(cUv.y, 0.);
    cUv *= inBorder / cornerSize;

    float cBorderSize = cornerSize - borderSize;
    float b = smoothstep(cBorderSize, cBorderSize + SMOOTHSTEP_BORDER, drawCircle(cUv) * cornerSize);
    vec2 bUv = arCorrection - inUv;
    float b2 = smoothstep(borderSize + SMOOTHSTEP_BORDER, borderSize, min(bUv.x, bUv.y));

    b = mix(b, b2, 1.0 - inBorder);

    return mix(b, b2, 1.0 - inBorder);
}

float drawSquare(vec2 inUv) {
    inUv = abs(inUv * arCorrection);
    vec2 bUv = arCorrection - inUv;
    float b = smoothstep(borderSize + SMOOTHSTEP_BORDER, borderSize, min(bUv.x, bUv.y));
    return b;
}

void main() {
    fragColor = color;
    float border = 0.;
    vec2 uvAR = uv;
    arCorrection = aspectRatio > 1. ? vec2(aspectRatio, 1.0) : vec2(1.0, 1.0 / aspectRatio);
    // borderSize *= 0.025;
    // borderSize *= 0.f;
    // uvAR /= scale;

    // SMOOTHSTEP_BORDER /= scale;


    borderSize = 0.005;
    // borderSize /= pow(scale, 1.75);

    // borderSize = borderSize / (scale);

    // vec2 size = 

    borderSize = borderSize / (scale);
    // borderSize *= aspectRatio > 1. ? 0.1 * aspectRatio / scale : scale ;

    // borderSize = max(borderSize, 0.01);
    // borderSize = borderSize / max(arCorrection.y, arCorrection.x);
    // borderSize = borderSize * (min(arCorrection.y, arCorrection.x)/max(arCorrection.y, arCorrection.x));

    // arCorrection = vec2(1);

    switch(type) {
        case 0:
        case 3:
            // borderSize /= scale;
            // borderSize *= 0.1;
            // border = drawSquare(uvAR);
            break;

        case 2:
        case 5 : 
            uvAR *= arCorrection;

            border = drawCircle(uvAR)*0.00001;
            break;

        default :
            border = drawSquareRounded(
                // min(1.0, 0.05 / scale), 
                // 0.02/scale
                // 0.03 * max(arCorrection.x, arCorrection.y)
                // 30 / (max(arCorrection.x, arCorrection.y) / scale)
                // 0.75
                0.333
                ,

                uvAR);
            break;
    }

    switch(type) {
        case 3:
            fragColor.rgb = hsv2rgb(
                rgb2hsv(color.rgb)*vec3(1., 0., 0.) 
                + vec3(0, uv*0.5 + 0.5)
                );
            break;

        case 4:
            fragColor.rgb = hsv2rgb(
                vec3(uv.x*0.5 + 0.5, 1., 1.)
                );
            fragColor.a *= 2;
            break;
        
        case 5 : 

            uvAR.x *= -1;

            uvAR.y += 0.5;

            float a = PI*-0.275f;
            uvAR += vec2(
                uvAR.x*cos(a) - uvAR.y*sin(a),
                uvAR.x*sin(a) + uvAR.y*cos(a)
            );

            /**** TODO : adjust ****/
            if(uvAR.x > 0.0)
            {
                // uvAR -= -0.2*uvAR.x*(distance(uvAR.x, 0.0));
            }
            else
            {
                // uvAR -= 1.0*uvAR.x*(distance(uvAR.x, 0.0));
            }

            uvAR.y *= pow(abs(uvAR.y), 0.2);
            // uvAR.x /= 10.f;

            sunDir = normalize(vec3(uvAR.x, uvAR.y*2.0, -5.0));
            fragColor.rgb = getSkyColor(normalize(vec3(0, 0.3, 1)));
            

            // moonPos = normalize(vec3(-uvAR.x, -uvAR.y, 1));
            // moonPos *= 1e6;

            // moonPos.y *= -1;
            // fragColor.rgb = getAtmopshereColor(normalize(vec3(0, 0.3, 1)));

            fragColor.rgb += pow(max(-sunDir.y, 0.), 0.5) * getStars(
                -sunDir, 
                0.3, 
                50, 
                0.5);

            // {
            //     sunDir = sunDir = normalize(vec3(uvAR.x, -uvAR.y, 1));
            //     fragColor.rgb += pow(getSkyColor(normalize(vec3(0, 0.3, 1))), vec3(5.0));
            // }
                // fragColor.rgb = pow(fragColor.rgb, vec3(0.4));


            fragColor.rgb = pow(fragColor.rgb, vec3(0.75));
            fragColor.a   *= 5.0;
            break;
    }


    // fragColor.a = 0.9;
    // border = drawSquareRounded(min(1.0, 0.05 / scale), uvAR);


    // fragColor.rgb = vec3(cos(_iTime)*0.5 + 0.5, 0.75, 0.75);
    // fragColor.rgb = hsv2rgb(fragColor.rgb);
    // fragColor.rgb *= (1.0 - border) * 0.5 + 0.5;

    // if(border > 0.0)
    // {
    //     fragColor.rgb = rgb2hsv(fragColor.rgb);        
    //     fragColor.z = fragColor.z * pow(1.0-fragColor.z, 0.5);
    //     fragColor.rgb = hsv2rgb(fragColor.rgb);
        
    //     fragColor.a += sign(fragColor.a)*0.1;
    // }
    // else
    // {

    // }

    // fragColor.a = border;

    // fragColor.rgb = vec3(0.0, arCorrection.x, arCorrection.y)*0.05;
    // fragColor.rgb = vec3(0.0, scale / arCorrection.y, 0.0);

    // fragColor.rgb = getAtmopshereColor(normalize(vec3(1.0, uvAR.y, uvAR.x)));
    
    fragColor = mix(fragColor, fragColor * vec4(vec3(1.0), 0.4), border);


    if(fragColor.a == 0.f) discard;
    // fragColor.a = 1;
}
