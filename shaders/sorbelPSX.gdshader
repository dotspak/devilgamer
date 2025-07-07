shader_type spatial;
render_mode unshaded, fog_disabled;

global uniform vec2 resolution;
global uniform float colorDepth;

uniform float ditherAmount : hint_range(0.0, 1.0, 0.01) = 0.5;

const mat4 bayerMatrix = (1.0 / 16.0) * mat4 (
	vec4(0.0, 8.0, 2.0, 10.0),
	vec4(12.0, 4.0, 14.0, 6.0),
	vec4(3.0, 11.0, 1.0, 9.0),
	vec4(15.0, 7.0, 13.0, 9.0)
) - 0.5;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_nearest;
uniform sampler2D NORMAL_TEXTURE : hint_normal_roughness_texture, filter_nearest;

uniform float edge_threshold = 1.0;
uniform float edge_thickness = 1.0;
uniform vec3 line_color: source_color = vec3(0.0, 0.0, 0.0);
uniform vec3 background_color: source_color = vec3(0.408, 0.969, 0.694);

const mat3 sobel_y = mat3(
	vec3(1.0, 0.0, -1.0),
	vec3(2.0, 0.0, -2.0),
	vec3(1.0, 0.0, -1.0)
);

const mat3 sobel_x = mat3(
	vec3(1.0, 2.0, 1.0),
	vec3(0.0, 0.0, 0.0),
	vec3(-1.0, -2.0, -1.0)
);

vec3 normalize_normal(vec3 normal){
	return normalize(normal * 2.0 - 1.0);
}

void vertex(){
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	// sorbel lines pass
	vec2 uv = SCREEN_UV;
	vec4 screen_color = texture(SCREEN_TEXTURE, uv);
	vec2 offset = edge_thickness / VIEWPORT_SIZE;
	vec3 normal = normalize_normal(texture(NORMAL_TEXTURE, uv).rgb);

	vec3 n = normalize_normal(texture(NORMAL_TEXTURE, uv + vec2(0.0, -offset.y)).rgb);
	vec3 s = normalize_normal(texture(NORMAL_TEXTURE, uv + vec2(0.0, offset.y)).rgb);
	vec3 e = normalize_normal(texture(NORMAL_TEXTURE, uv + vec2(offset.x, 0.0)).rgb);
	vec3 w = normalize_normal(texture(NORMAL_TEXTURE, uv + vec2(-offset.x, 0.0)).rgb);
	vec3 nw = normalize_normal(texture(NORMAL_TEXTURE, uv + vec2(-offset.x, -offset.y)).rgb);
	vec3 ne = normalize_normal(texture(NORMAL_TEXTURE, uv + vec2(offset.x, -offset.y)).rgb);
	vec3 sw = normalize_normal(texture(NORMAL_TEXTURE, uv + vec2(-offset.x, offset.y)).rgb);
	vec3 se = normalize_normal(texture(NORMAL_TEXTURE, uv + vec2(offset.x, offset.y)).rgb);

	mat3 surrounding_pixels = mat3(
		vec3(length(nw-normal), length(n-normal), length(ne-normal)),
		vec3(length(w-normal), length(normal-normal), length(e-normal)),
		vec3(length(sw-normal), length(s-normal), length(se-normal))
	);

	float edge_x = dot(sobel_x[0], surrounding_pixels[0]) + dot(sobel_x[1], surrounding_pixels[1]) + dot(sobel_x[2], surrounding_pixels[2]);
	float edge_y = dot(sobel_y[0], surrounding_pixels[0]) + dot(sobel_y[1], surrounding_pixels[1]) + dot(sobel_y[2], surrounding_pixels[2]);

	float edge = sqrt(pow(edge_x, 2.0)+pow(edge_y, 2.0));

	vec3 sobelColor = (edge > edge_threshold) ? line_color : screen_color.rgb;
	//if (edge > edge_threshold) {
		//ALBEDO = line_color;
	//} else {
		//ALBEDO = screen_color.rgb;
	//}

	// psx filter pass
	vec2 psxUV = floor(SCREEN_UV * resolution) / resolution;
	ivec2 intUV = ivec2(psxUV * resolution);
	//vec3 color = texture(SCREEN_TEXTURE, psxUV).rgb;
	vec3 dither = sobelColor + bayerMatrix[intUV.x % 4][intUV.y % 4] / colorDepth * ditherAmount;
	vec3 quantized = round(dither * colorDepth) / colorDepth;
	ALBEDO = quantized;
}
