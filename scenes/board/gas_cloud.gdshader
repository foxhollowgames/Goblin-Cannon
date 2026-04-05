shader_type canvas_item;
render_mode blend_mix;

// Green toxic gas: soft billowy body + animated contour / topo lines.
uniform vec4 gas_dark : source_color = vec4(0.05, 0.22, 0.08, 1.0);
uniform vec4 gas_mid : source_color = vec4(0.12, 0.55, 0.18, 1.0);
uniform vec4 gas_bright : source_color = vec4(0.45, 0.95, 0.42, 1.0);
uniform vec4 line_color : source_color = vec4(0.02, 0.35, 0.06, 1.0);
uniform float noise_seed : hint_range(0.0, 1000.0) = 0.0;
uniform float noise_scale : hint_range(0.5, 20.0) = 6.0;
uniform float time_speed : hint_range(0.0, 0.4) = 0.1;
uniform float contour_bands : hint_range(4.0, 28.0) = 16.0;
uniform float line_thickness : hint_range(0.02, 0.12) = 0.055;
uniform float contour_strength : hint_range(0.0, 1.0) = 0.55;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	vec2 shift = vec2(100.0 + noise_seed * 0.03, 50.0 + noise_seed * 0.02);
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p = p * 2.08 + shift;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 uv = UV * 2.0 - 1.0;
	float dist = length(uv);
	float mask = 1.0 - smoothstep(0.72, 1.0, dist);

	vec2 p = UV * noise_scale + vec2(noise_seed * 0.019, noise_seed * 0.011);
	p += TIME * time_speed * vec2(0.31, -0.24);
	float h = fbm(p + fbm(p * 1.65 + vec2(noise_seed * 0.01)));
	h = clamp(h * 0.55 + 0.36, 0.0, 1.0);

	// Billowy body (smooth ramps between greens)
	vec3 body = mix(gas_dark.rgb, gas_mid.rgb, smoothstep(0.2, 0.55, h));
	body = mix(body, gas_bright.rgb, smoothstep(0.55, 0.92, h) * h);

	// Topographic contour lines: bright/dark strips where fract(h * bands) wraps
	float bands = contour_bands;
	float t = fract(h * bands);
	float line = 1.0 - smoothstep(0.0, line_thickness, t);
	line = max(line, 1.0 - smoothstep(1.0 - line_thickness, 1.0, t));
	float line_alpha = line * contour_strength;

	vec3 col = mix(body, line_color.rgb, line_alpha);
	// Slight inner glow so it does not read as flat white
	col *= 0.92 + 0.08 * h;

	float alpha = mask * (0.22 + 0.62 * h + 0.18 * line) * tex.a;
	alpha = clamp(alpha, 0.0, 1.0);

	COLOR = vec4(col, alpha);
}
