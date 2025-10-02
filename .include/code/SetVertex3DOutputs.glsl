
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

// #ifndef IN_SKYBOX_MESH
{
    #define BASE_SIZE 8192 * 2.
    #ifdef IN_SKYBOX_MESH
    const float planetSize = BASE_SIZE * 64 * 4.;
    #else
    const float planetSize = BASE_SIZE;
    #endif

    float d = distance(position.xz, _cameraPosition.xz)/planetSize;

    d = sin(acos(d));

    d -= 1.;
    d *= planetSize;

    if(abs(d) < 0.5) d = 0;

    position.y += d;

    #ifdef IN_SKYBOX_MESH
    position.y += 9e4;
    #endif
}
// #endif