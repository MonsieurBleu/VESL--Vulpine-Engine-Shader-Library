
#ifndef USING_VERTEX_TEXTURE_UV
    #ifndef USING_VERTEX_PACKING
        vcolor = _color;
    #endif
#else
    #ifndef DONT_RETREIVE_UV
    uv = vec2(_uv.x , 1.0 - _uv.y);
    #endif
#endif

normal = normalize(modelMatrix * vec4(normal, 0.0)).rgb;
position = (modelMatrix * vec4(positionInModel, 1.0)).rgb;
viewVector = _cameraPosition - position;

#ifndef IN_SKYBOX_MESH
#define DO_FAKE_PLANET_CURVATURE
#else
    // position.y -= 12e5;

    position.y -= 10e5;

    // position.y = max(0., position.y);

    // if(position.y < -300000)
    //     position = vec3(-300000);
    
#endif


#ifdef DO_FAKE_PLANET_CURVATURE
{
    #ifdef IN_SKYBOX_MESH
    const float planetSize = PLANET_SIZE * 64 * 4.;
    #else
    const float planetSize = PLANET_SIZE;
    #endif

    vec2 pc = position.xz - _cameraPosition.xz;
    float d = planetSize * (sqrt(1.0 - dot(pc, pc)/(planetSize*planetSize)) - 1.0);
    position.y += d;

    #ifdef IN_SKYBOX_MESH
    position.y += 9e4;
    if(position.y > -200000)
        position.y /= 3.0;
    // else
    //     position = vec3(-200000);
    
    // position.y /= mix(5., 1., smoothstep(1e6, 0.0, position.y));

    

    // position.y += 1e5;

    // position *= 0.05;

    // position.y = 1000.0;

    // position.y = mix(position.y, 10000.0, 0.85);


    #endif
}
#endif