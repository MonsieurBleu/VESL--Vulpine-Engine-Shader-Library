#version 460

#define USING_VERTEX_TEXTURE_UV

 #include Base3D 
 #include Model3D 

layout(location = 0) in vec3 _position;

out vec2 uv;

out vec2 scale;

void main() {
    uv = _position.xy*vec2(1, -1);

    vec3 position = (_modelMatrix * vec4(_position, 1.0)).rgb;


    scale = vec2(
        length(vec3(_modelMatrix[0].x, _modelMatrix[1].x, _modelMatrix[2].x)),
        length(vec3(_modelMatrix[0].y, _modelMatrix[1].y, _modelMatrix[2].y))
    );

    position.z = _modelMatrix[3].z + 0.01;

    gl_Position = vec4(position, 1.0);
};