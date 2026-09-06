shader_type canvas_item;

uniform float cloud_breathe_speed : hint_range(0.0, 3.0) = 0.4;
uniform float cloud_breathe_amount : hint_range(0.0, 0.15) = 0.06;
uniform float twinkle_speed : hint_range(0.0, 5.0) = 2.0;
uniform float twinkle_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float water_shimmer_speed : hint_range(0.0, 3.0) = 1.0;
uniform float water_shimmer_amount : hint_range(0.0, 0.1) = 0.04;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	vec4 col = texture(TEXTURE, uv);

	// ── SKY REGION (top ~45%) ──
	float sky_mask = smoothstep(0.5, 0.4, uv.y);

	// Cloud "breathing" — subtle brightness wave across clouds
	// Clouds sit around y=0.25-0.55, so use a bell curve centered there
	float cloud_zone = exp(-pow((uv.y - 0.38) * 5.0, 2.0));
	float cloud_wave = sin(TIME * cloud_breathe_speed + uv.x * 4.0) * cloud_breathe_amount;
	col.rgb += cloud_wave * cloud_zone;

	// Stars in the dark sky — twinkle bright pixels
	float sky_darkness = 1.0 - sky_mask; // 1 in dark sky, 0 at horizon
	float star_brightness = (col.r + col.g + col.b) / 3.0;
	float is_star = step(0.35, star_brightness) * sky_darkness;
	// Each star gets a unique random phase
	float star_id = hash(floor(uv * 600.0));
	float twinkle = sin(TIME * twinkle_speed * (0.7 + star_id * 0.6) + star_id * 6.28) * 0.5 + 0.5;
	col.rgb += is_star * twinkle * twinkle_intensity;

	// ── WATER REGION (bottom ~40%) ──
	float water_mask = smoothstep(0.5, 0.6, uv.y);

	// Shimmer — gentle brightness wave on the water surface
	float shimmer = sin(TIME * water_shimmer_speed + uv.x * 8.0 + uv.y * 12.0) * water_shimmer_amount;
	col.rgb += shimmer * water_mask;

	// Water sparkles — bright dots twinkle on the water
	float water_brightness = (col.r + col.g + col.b) / 3.0;
	float is_sparkle = step(0.55, water_brightness) * water_mask;
	float sparkle_id = hash(floor(uv * 500.0) + 100.0);
	float sparkle = sin(TIME * twinkle_speed * 1.3 + sparkle_id * 6.28) * 0.5 + 0.5;
	col.rgb += is_sparkle * sparkle * twinkle_intensity * 0.7;

	COLOR = col;
}
