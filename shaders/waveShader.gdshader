shader_type canvas_item;

uniform vec4 color : source_color = vec4(0, 0.2, 1.0, 1);
uniform float alpha = 0.5;
uniform sampler2D noise : repeat_enable;
uniform sampler2D SCREEN : hint_screen_texture;

uniform vec2 speed = vec2(0.03, 0.06);
uniform float waveStrength = 2;
uniform float distortion = 0.01;

void fragment() {
	vec2 uv = UV + speed * TIME;
	vec2 n = 2.0 * texture(noise, uv).rg - vec2((1.0 - distortion) + 0.4);

	COLOR = texture(TEXTURE, UV + n * waveStrength);
	COLOR.rgb *= color.rgb;
	COLOR *= texture(SCREEN, SCREEN_UV + n * distortion);
	COLOR.a = alpha;
}