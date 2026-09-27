shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_strength : hint_range(0.0, 1) = 0.05;
uniform int samples = 12;

void fragment() {
    // Center of the screen is (0.5, 0.5)
    vec2 center = vec2(0.5, 0.5);
    vec2 uv = SCREEN_UV;
    vec2 dir = uv - center;
    
    vec4 color = vec4(0.0);
    
    // Scale blur based on distance from center (edges blur more, center stays sharp)
    float dist = length(dir);
    vec2 blur_vector = dir * dist * blur_strength;

    for(int i = 0; i < samples; i++) {
        float scale = float(i) / float(samples - 1);
        color += texture(screen_texture, uv - (blur_vector * scale));
    }
    
    COLOR = color / float(samples);
}
