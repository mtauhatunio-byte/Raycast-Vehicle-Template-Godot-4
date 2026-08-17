shader_type sky;

uniform sampler2D panorama_texture : source_color, filter_linear_mipmap;
uniform float scroll_speed : hint_range(-1.0, 1.0) = 0.05;

void sky() {
	// Use Godot's built-in SKY_COORDS for proper 360 projection
	// Add TIME to the X coordinate to loop seamlessly horizontally
	vec2 animated_uv = SKY_COORDS + vec2(TIME * scroll_speed, 0.0);
	
	// Sample the texture and output the final color
	COLOR = texture(panorama_texture, animated_uv).rgb;
}
