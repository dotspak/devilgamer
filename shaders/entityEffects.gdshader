shader_type spatial;

uniform vec3 flashColor : source_color = vec3(1,0,0);
uniform float flash = 0;

void fragment() {
	vec3 baseColor = ALBEDO.rgb;
	vec3 flashEffect = mix(baseColor, flashColor, flash);
	ALBEDO = flashEffect;
}
