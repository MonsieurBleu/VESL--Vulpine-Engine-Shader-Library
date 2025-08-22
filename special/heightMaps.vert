#version 460

#define USING_VERTEX_TEXTURE_UV

 #include Base3D 
 #include Model3D 

 #include Vertex3DInputs 
 #include Vertex3DOutputs 

#ifdef ARB_BINDLESS_TEXTURE
layout (location = 22, bindless_sampler) uniform sampler2D bHeight;
layout (location = 23, bindless_sampler) uniform sampler2D bDisp;
#else
layout(binding = 2) uniform sampler2D bHeight;
layout(binding = 3) uniform sampler2D bDisp;
#endif

void main()
{
    mat4 modelMatrix = _modelMatrix;
    vec3 positionInModel = _positionInModel;
    normal = _normal;

    // positionInModel.y += cos(positionInModel.x + 4.5);
    // positionInModel.y += positionInModel.x;

        

    uv = vec2(_uv.x , 1.0 - _uv.y);
    uv = clamp(uv, vec2(0.001), vec2(0.999));
    const float uvcScale = 16.0;
    vec2 uvc = uv*uvcScale;
    
    vec3 modPos2 = _positionInModel + normal.yxz*0.01;
    vec3 modPos3 = _positionInModel + normal.xzy*0.01;

    const float hmBias = 0.01;
    float h0 = texture(bHeight, uv).r;
    float h1 = texture(bHeight, uv + vec2(hmBias, 0.0)).r;
    float h2 = texture(bHeight, uv + vec2(0.0, hmBias)).r;

    h0 = h0-0.5;
    h1 = h1-0.5;
    h2 = h2-0.5;

    const float hmAmplitude = 1.0;
    positionInModel += normal*h0*hmAmplitude;
    modPos2 += normal*h1*hmAmplitude;
    modPos3 += normal*h2*hmAmplitude;
    normal = normalize(cross((modPos3 - positionInModel), (modPos2 - positionInModel)));

/******* DISPLACEMENT MAP *******/
    const float dmBias = 0.01;
    float d0 = texture(bDisp, uvc).r;
    float d1 = texture(bDisp, uvc + vec2(dmBias, 0.0)).r;
    float d2 = texture(bDisp, uvc + vec2(0.0, dmBias)).r;

    const float dmAmplitude = 0.01;
    positionInModel += normal*(d0 - 0.5)*dmAmplitude;
    modPos2 += normal*(d1 - 0.5)*dmAmplitude;
    modPos2 += normal*(d2 - 0.5)*dmAmplitude;
    // normal = normalize(cross((modPos3 - positionInModel), (modPos2 - positionInModel)));

    // positionInModel += normal*0.05;
/****************/

    



    

    // vec3 perturb;
    // perturb = vec3(1, 0, 0)*(h0-h1) + vec3(0, 0, 1)*(h0-h2);

    // normal = normalize(normal + perturb*32.0);

    // uvc *= positionInModel.xz*normal.xz;


     #include SetVertex3DOutputs 

    uv = uvc;

    gl_Position = _cameraMatrix * vec4(position, 1.0);
};