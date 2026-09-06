shader_type canvas_item;

uniform float threshold : hint_range(0.0, 1.0) = 0.7;
uniform float edge_smooth : hint_range(0.0, 0.3) = 0.1;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float brightness = (col.r + col.g + col.b) / 3.0;
	if (brightness > threshold) {
		float factor = smoothstep(threshold, threshold + edge_smooth, brightness);
		col.a *= (1.0 - factor);
	}
	COLOR = col;
}
