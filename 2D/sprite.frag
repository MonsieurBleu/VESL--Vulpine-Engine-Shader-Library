#version 460

 #include Base3D 
 #include Model3D 

layout (location = 0) out vec4 fragColor;

layout (binding = 0) uniform sampler2D bTexture;

in vec2 uv;

in vec2 scale;

void main()
{
    vec2 tSize = vec2(textureSize(bTexture, 0));

    vec2 auv = uv;
    vec2 ascale = scale;
    // auv.y /= float(_iResolution.x)/float(_iResolution.y);

    // auv.y *= tSize.x/tSize.y;

    ascale.y /= float(_iResolution.x)/float(_iResolution.y);

    if(ascale.x > ascale.y)
    {
        auv.x *= ascale.x/ascale.y;
        
        // auv.x -= scale.x * (float(_iResolution.x)/float(_iResolution.y));
        auv.x -= 0.5 * (scale.x/scale.y) * (float(_iResolution.x)/float(_iResolution.y));
        auv.x += 0.5;
    }
    else
    {

        auv.y /= ascale.x/ascale.y;

        auv.y += 0.5;

        auv.y -= 0.5 * (scale.y/scale.x) * (float(_iResolution.y)/float(_iResolution.x));

        // auv.y -= scale.y;
    }

    // fragColor = vec4(ascale, 0, 1);

    // auv.y /= scale.x/scale.y;
    // auv.x *= scale.x/scale.y;

    fragColor = texture(bTexture, auv);
    float bias = 1e-3;
    if(
        auv.x < bias || auv.y < bias || auv.x > 1-bias || auv.y > 1-bias
    )
        discard;
    
    if(fragColor.a == 0.f) discard;
}