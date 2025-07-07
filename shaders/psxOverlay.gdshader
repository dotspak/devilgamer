shader_type spatial;
render_mode unshaded, fog_disabled;

global uniform vec2 resolution;
global uniform float colorDepth;

uniform float ditherAmount : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform sampler2D screenTexture : hint_screen_texture, filter_nearest;

const mat4 bayerMatrix = (1.0 / 16.0) * mat4 (
	vec4(0.0, 8.0, 2.0, 10.0),
	vec4(12.0, 4.0, 14.0, 6.0),
	vec4(3.0, 11.0, 1.0, 9.0),
	vec4(15.0, 7.0, 13.0, 9.0)
) - 0.5;

void vertex() { POSITION = vec4(VERTEX.xy, 1.0, 1.0); }

void fragment() {
	vec2 uv = floor(SCREEN_UV * resolution) / resolution;
	ivec2 intUV = ivec2(uv * resolution);
	vec3 color = texture(screenTexture, uv).rgb;
	vec3 dither = color + bayerMatrix[intUV.x % 4][intUV.y % 4] / colorDepth * ditherAmount;
	vec3 quantized = round(dither * colorDepth) / colorDepth;
	ALBEDO = quantized;
}
