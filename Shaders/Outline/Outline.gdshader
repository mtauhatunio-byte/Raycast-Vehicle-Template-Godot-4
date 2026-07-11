shader_type canvas_item;
render_mode unshaded;

uniform float outline_width : hint_range(0.0, 5.0) = 1.5;
uniform float color_threshold : hint_range(0.0, 1.0) = 0.15;
uniform vec4 edge_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

// --- TARGET 0-255 INPUTS ---
// Set these parameters to 250, 250, 250 in your Godot Inspector tab!
uniform vec3 target_rgb_255 = vec3(250.0, 250.0, 250.0); 
uniform float exclusion_tolerance : hint_range(0.0, 1.0) = 0.08;     

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_linear;

void fragment() {
    vec2 size = vec2(textureSize(SCREEN_TEXTURE, 0));
    vec2 uv_offset = outline_width / size;

    vec2 uv_u = SCREEN_UV + vec2(0.0, uv_offset.y);
    vec2 uv_d = SCREEN_UV + vec2(0.0, -uv_offset.y);
    vec2 uv_l = SCREEN_UV + vec2(-uv_offset.x, 0.0);
    vec2 uv_r = SCREEN_UV + vec2(uv_offset.x, 0.0);

    vec3 col = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
    vec3 col_u = texture(SCREEN_TEXTURE, uv_u).rgb;
    vec3 col_d = texture(SCREEN_TEXTURE, uv_d).rgb;
    vec3 col_l = texture(SCREEN_TEXTURE, uv_l).rgb;
    vec3 col_r = texture(SCREEN_TEXTURE, uv_r).rgb;

    float color_diff = distance(col_u, col_d) + distance(col_l, col_r);
    float final_edge = step(color_threshold, color_diff);

    // --- FIXED: NORMALIZE 255 INPUT RANGE TO 0.0-1.0 ENGINE RANGE ---
    vec3 normalized_exclude_color = target_rgb_255 / 255.0;
    
    // Measure distance against the newly converted, accurate floating point values
    float color_distance = distance(col, normalized_exclude_color);
    
    if (color_distance < exclusion_tolerance) {
        final_edge = 0.0; // Cleanly cancels outline overhead on cloud blocks
    }

    vec3 final_output_color = mix(col, edge_color.rgb, final_edge);
    
    COLOR.rgb = final_output_color;
    COLOR.a = 1.0; 
}
