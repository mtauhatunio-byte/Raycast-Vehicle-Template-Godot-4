shader_type spatial;

uniform sampler2D road_texture : hint_default_white, filter_linear_mipmap, repeat_enable;
// Adds a slider in your right-hand Inspector panel to manually line it up perfectly
uniform float road_center_offset : hint_range(-2.0, 2.0) = 0.125;

void fragment() {
    // 1. Swap UVs to keep it rotated correctly
    vec2 road_uv = vec2(UV.y, UV.x);
    
    // 2. Multiply UV components to control tiling frequency
    road_uv.x *= 10.0; 
    road_uv.y *= 1.0; 
    
    // 3. Shift the width layout to fix the off-center alignment
    road_uv.x += road_center_offset;
    
    vec4 color = texture(road_texture, road_uv);
    ALBEDO = color.rgb;
    METALLIC = 0.0;
    ROUGHNESS = 0.8;
}
