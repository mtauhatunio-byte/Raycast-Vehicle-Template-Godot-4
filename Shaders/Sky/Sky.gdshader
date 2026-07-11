shader_type sky;

uniform sampler2D sky_texture;
uniform float power = 0.5;
uniform float scale = 0.5;
uniform float speed = 0.1;
uniform float density = 0.1;

uniform vec3 sky_color_a : source_color = vec3(0.5, 0.8, 1.0);
uniform vec3 sky_color_b : source_color = vec3(0.3, 0.5, 1.0);

uniform vec3 ground_color_a : source_color = vec3(1.0, 0.8, 0.5);
uniform vec3 ground_color_b : source_color = vec3(1.0, 0.5, 0.3);

vec3 do_ceil(vec3 eye) {
	return mix(sky_color_a, sky_color_b, eye.y);
}

vec3 do_floor(vec3 eye) {
	return mix(ground_color_a, ground_color_b, -eye.y);
}

void sky() {
	float fade = pow(abs(EYEDIR.y), power);
	vec3 clouds = texture(sky_texture, (EYEDIR.xz / EYEDIR.y) * scale + vec2(TIME * speed)).rgb * fade;
	vec3 sky_back = EYEDIR.y > 0.0 ? do_ceil(EYEDIR) : vec3(0.0);
	float dens = smoothstep(density, 1.0, clouds.r);
	
	COLOR = vec3(0.0);
	COLOR = EYEDIR.y > 0.0 ? mix(sky_back, clouds, dens) : COLOR;
	COLOR += EYEDIR.y < 0.0 ? do_floor(EYEDIR) : vec3(0.0);
}
