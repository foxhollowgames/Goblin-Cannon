shader_type canvas_item;
// Slight blur of screen content behind the reward modal (§1.10).
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 8.0) = 1.5;

void fragment() {
	COLOR = textureLod(screen_texture, SCREEN_UV, blur_amount);
}
