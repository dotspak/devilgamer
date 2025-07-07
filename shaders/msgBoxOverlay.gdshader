shader_type canvas_item;

uniform float blur_radius = 2.0; // How far the blur samples go
uniform int blur_steps = 5; // Number of blur samples (per direction)
uniform float chromatic_strength = 1.5; // Pixel offset for chromatic aberration
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 pixel_size = 1.0 / vec2(textureSize(SCREEN_TEXTURE, 0));

    vec4 blurred = vec4(0.0);
    float total = 0.0;

    // Gaussian blur approximation
    for (int x = -blur_steps; x <= blur_steps; x++) {
        for (int y = -blur_steps; y <= blur_steps; y++) {
            float weight = 1.0 - length(vec2(float(x), float(y)) / float(blur_steps));
            vec2 offset = vec2(float(x), float(y)) * pixel_size * blur_radius;
            blurred += texture(SCREEN_TEXTURE, uv + offset) * weight;
            total += weight;
        }
    }
    blurred /= total;

    // Chromatic aberration offsets
    vec2 offset_r = uv + pixel_size * chromatic_strength;
    vec2 offset_g = uv;
    vec2 offset_b = uv - pixel_size * chromatic_strength;

    float r = texture(SCREEN_TEXTURE, offset_r).r;
    float g = texture(SCREEN_TEXTURE, offset_g).g;
    float b = texture(SCREEN_TEXTURE, offset_b).b;

    vec4 chroma = vec4(r, g, b, 1.0);

    // Blend between blurred texture and chromatic aberration
    COLOR = mix(chroma, blurred, 0.5);
}
