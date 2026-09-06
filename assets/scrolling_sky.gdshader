shader_type canvas_item;

// Drop this on a TextureRect (or Sprite2D) using seamless_bg.png.
// Make sure the texture's import "Repeat" mode is set to "Enabled".

uniform float cloud_speed : hint_range(0.0, 1.0) = 0.02; // UV units per second
uniform float water_line : hint_range(0.0, 1.0) = 0.62;  // fraction of height where water starts
uniform float star_density : hint_range(1.0, 40.0) = 18.0;
uniform float star_speed : hint_range(0.1, 5.0) = 1.2;

// simple hash for pseudo-random star placement
float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 34.45);
    return fract(p.x * p.y);
}

void fragment() {
    // scroll only the horizontal UV, wraps automatically because the
    // texture is seamless and repeat is enabled on the import
    vec2 uv = UV;
    uv.x += TIME * cloud_speed;

    vec4 col = texture(TEXTURE, uv);

    // twinkling stars overlay, confined to the water region below water_line
    if (UV.y > water_line) {
        vec2 grid = UV * star_density;
        vec2 cell = floor(grid);
        vec2 f = fract(grid);

        float r = hash21(cell);
        // only some cells contain a star
        if (r > 0.85) {
            vec2 starPos = vec2(hash21(cell + 0.11), hash21(cell + 0.37));
            float d = distance(f, starPos);
            float twinkle = 0.5 + 0.5 * sin(TIME * star_speed * 6.2831 + r * 50.0);
            float glow = smoothstep(0.09, 0.0, d) * twinkle;
            col.rgb += glow * vec3(1.0, 0.97, 0.85);
        }
    }

    COLOR = col;
}
