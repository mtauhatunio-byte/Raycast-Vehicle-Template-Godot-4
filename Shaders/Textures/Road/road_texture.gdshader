shader_type spatial;

uniform vec3 center_lines : source_color = vec3(1, 1, 1); // White center lane line
uniform vec3 side_lines : source_color = vec3(1, 1, 0);   // Yellow edge lines
uniform vec3 color : source_color = vec3(0.1, 0.1, 0.1);  // Dark gray asphalt road base

float draw_smooth_line(float uv_axis, float start, float end) {
    float delta = fwidth(uv_axis);
    float left_edge = smoothstep(start - delta, start + delta, uv_axis);
    float right_edge = smoothstep(end + delta, end - delta, uv_axis);
    return left_edge * right_edge;
}

void fragment() {
    // 1. Lock the line positions across the horizontal width of the road
    float road_width = UV.x; 
    
    // 2. Lock the line rendering across the vertical length of the track
    // fract() forces the mesh texture generation to repeat down the track loop infinitely
    float track_length = fract(UV.y);
    
    // 3. Calculate smooth outer gutters (using the width axis)
    float left_line_mask = draw_smooth_line(road_width, 0.05, 0.1);
    float right_line_mask = draw_smooth_line(road_width, 0.9, 0.95);
    float side_mask = clamp(left_line_mask + right_line_mask, 0.0, 1.0);
    
    // 4. Calculate a perfectly centered dividing line
    float center_mask = draw_smooth_line(road_width, 0.48, 0.52);
    
    // 5. Combine the masks and apply them down the track length
    // Multiplying by step() ensures the lines exist through the repeating length pass
    float line_presence = step(0.0, track_length);
    
    vec3 final_color = color;
    final_color = mix(final_color, center_lines, center_mask * line_presence);
    final_color = mix(final_color, side_lines, side_mask * line_presence);
    
    ALBEDO = final_color;
}
