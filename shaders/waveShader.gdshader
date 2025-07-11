shader_type canvas_item;

uniform vec4 color : source_color = vec4(0, 0.2, 1.0, 1);
uniform sampler2D noise : repeat_enable;
uniform sampler2D SCREEN : hint_screen_texture;

uniform vec2 speed = vec2(0.03, 0.06);
uniform float waveStrength = 2;

void fragment() {
	vec2 uv = UV + speed * TIME;
	vec2 n = texture(noise, uv).rg;

	COLOR = texture(SCREEN, SCREEN_UV + n * (waveStrength / 100.0));
	COLOR *= color + vec4(n.x, n.y, 1, 0);
}