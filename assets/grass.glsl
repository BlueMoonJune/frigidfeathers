
extern Image noise;
extern mat4 transform;
extern float time;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
	vec4 c = Texel(tex, texture_coords);
	vec2 world = (transform * vec4(screen_coords, 0, 1)).xy;
	if (c.a > 0.9 && c.g > c.r && Texel(noise, floor(world) / 300).r > 1 - mod(time, 2)) {
		float v = (c.r+c.g+c.b)/3.0;
		v = 1.0-pow(1.0-v, 4.0) + 0.25;
		c.rgb = vec3(v, v, v);
	}
	return c;
}
