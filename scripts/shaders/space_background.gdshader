shader_type canvas_item;

uniform vec4 bg_color : source_color = vec4(0.02, 0.02, 0.06, 1.0);
uniform vec2 offset = vec2(0.0, 0.0);

// --- Star settings ---
uniform float small_star_amount = 0.0015;
uniform float small_star_slow = 14.0;
uniform float small_star_size = 1.0;

// --- Nebula settings ---
uniform float nebula_scale = 0.002;
uniform float nebula_strength = 1;
uniform float nebula_parallax = 40.0;

// Nebula colors
uniform vec3 nebula_color_a = vec3(0.25, 0.10, 0.45); // purple
uniform vec3 nebula_color_b = vec3(0.05, 0.35, 0.55); // teal
uniform vec3 nebula_color_c = vec3(0.95, 0.35, 0.65); // pink

// NEW: independent strengths
uniform float nebula_strength_a = 0.5;
uniform float nebula_strength_b = 1;
uniform float nebula_strength_c = 0.5;

// --- Noise helpers ---
float rand(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    float a = rand(i);
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
           (c - a) * u.y * (1.0 - u.x) +
           (d - b) * u.x * u.y;
}

float fbm(vec2 st) {
    float value = 0.0;
    float scale = 0.5;
    for (int i = 0; i < 5; i++) {
        value += scale * noise(st);
        st *= 2.0;
        scale *= 0.5;
    }
    return value;
}

void fragment() {
    vec2 uv = FRAGCOORD.xy;

    // --- Small stars ---
    vec2 coord_small = FRAGCOORD.xy + floor(offset / small_star_slow);
    float star_intensity = 0.0;

    if (rand(coord_small / 24.0) > 1.0 - small_star_amount) {
        float r = rand(coord_small);
        float twinkle = 0.7 + 0.3 * sin(TIME * (r * 7.0) + 500.0 * r);
        star_intensity += r * twinkle * small_star_size;
    }

    // --- Nebula ---
    vec2 nebula_uv = (uv + offset / nebula_parallax) * nebula_scale;
    float n = fbm(nebula_uv);

    float intensity = pow(n, 1.8);

    // Independent color contributions
    vec3 col_a = nebula_color_a * nebula_strength_a * intensity;
    vec3 col_b = nebula_color_b * nebula_strength_b * intensity;
    vec3 col_c = nebula_color_c * nebula_strength_c * pow(n, 3.0);

    vec3 nebula_color = (col_a + col_b + col_c) * nebula_strength;

    vec3 final_color = bg_color.rgb + nebula_color + vec3(star_intensity);
    COLOR = vec4(final_color, 1.0);
}