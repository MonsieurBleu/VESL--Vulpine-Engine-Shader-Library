#ifndef FONT_GLSL
#define FONT_GLSL

float median(float r, float g, float b) {
	return max(min(r, g), min(max(r, g), b));
}

float getFontAlpha(sampler2D atlas, vec2 fuv)
{
    vec4 texel = texture(atlas, fuv);
    float dist = median(texel.r, texel.g, texel.b);

    float pxRange = 1.0;
    float pxDist = pxRange * (dist - 0.5);
	// float opacity = clamp(pxDist + 0.5, 0.0, 1.0);
    float opacity = smoothstep(-0.5, 0.25, pxDist);

    return opacity;
}

#endif