
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

