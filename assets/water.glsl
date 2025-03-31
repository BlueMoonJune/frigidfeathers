#pragma language glsl3

extern vec4[16] speeds;
extern int texCount;
extern float time;

const vec2 size = vec2(320, 320);

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {

	texture_coords = floor(texture_coords * size) / size;
	float v = 0.0;
	float w = 0.0;
	for (int i = 0; i < texCount; i++) {
		v += texture(tex, texture_coords * speeds[i].z + speeds[i].xy * time).a * speeds[i].w;
	}
	v = pow(1.0-v, 4);

	v = floor(v * 4.0) / 4.0;
	return mix(vec4(0.0, 0.05, 0.1, 1.0), vec4(0, 0.1, 0.2, 1.0), v);
	//return vec4(texture_coords, 0, 1) + v * 0.0001;
}
