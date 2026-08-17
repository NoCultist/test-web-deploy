shader_type spatial;

uniform float tile_size : hint_range(0.05, 10.0) = 0.5;
uniform float line_thickness : hint_range(0.001, 1.0) = 0.0075;
uniform vec3 line_color : source_color = vec3(0.0);
uniform vec3 base_color : source_color = vec3(1.0);
uniform float fade_radius : hint_range(0.1, 100.0) = 10.0;
uniform sampler2D fade_mask : hint_default_white, filter_linear, repeat_disable;

varying highp vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	highp vec2 coord = world_pos.xz / tile_size;
	highp vec2 dist_to_line = abs(fract(coord) - 0.5);
	dist_to_line = 0.5 - dist_to_line;
	float d = min(dist_to_line.x, dist_to_line.y);

	float thickness = line_thickness / tile_size;
	float aa = fwidth(d);
	float mask = 1.0 - smoothstep(thickness - aa, thickness + aa, d);

	highp vec2 fade_uv = world_pos.xz / (fade_radius * 2.0) + 0.5;
	float fade = texture(fade_mask, clamp(fade_uv, 0.0, 1.0)).r;
	mask *= fade;

	ALBEDO = mix(base_color, line_color, mask);
}
