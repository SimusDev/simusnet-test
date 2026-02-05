shader_type spatial;

// Настройки отрисовки: прозрачность и корректное освещение
render_mode depth_draw_always, diffuse_lambert, specular_schlick_ggx;

group_uniforms Base_Water;
uniform vec3 water_color : source_color = vec3(0.01, 0.1, 0.2);
uniform vec3 shallow_color : source_color = vec3(0.1, 0.4, 0.4);
uniform float depth_distance : hint_range(0.1, 10.0) = 2.0;

group_uniforms Waves_Physical;
uniform vec4 wave_1 = vec4(1.0, 0.0, 0.1, 5.0); // x,z - направление, y - крутизна, w - длина
uniform vec4 wave_2 = vec4(0.7, 0.7, 0.05, 2.5);
uniform float wave_speed = 1.0;
uniform float foam_multiplier = 1.0;

group_uniforms Textures_and_Effects;
uniform sampler2D normal_map : hint_normal, repeat_enable;
uniform sampler2D foam_noise : hint_default_white, repeat_enable;
uniform sampler2D ripple_texture : hint_default_black; // Для SubViewport ряби
uniform sampler2D depth_tex : hint_depth_texture;

// Математика волн Герстнера
vec3 calculate_gerstner(vec4 wave, vec3 p, inout vec3 tangent, inout vec3 binormal, float time) {
	float k = 2.0 * PI / wave.w;
	float f = k * (dot(normalize(wave.xz), p.xz) - (sqrt(9.8 / k) * time * wave_speed));
	float a = wave.y / k;
	vec2 d = normalize(wave.xz);

	float cos_f = cos(f);
	float sin_f = sin(f);

	tangent += vec3(-d.x * d.x * (wave.y * sin_f), d.x * (wave.y * cos_f), -d.x * d.y * (wave.y * sin_f));
	binormal += vec3(-d.x * d.y * (wave.y * sin_f), d.y * (wave.y * cos_f), -d.y * d.y * (wave.y * sin_f));

	return vec3(d.x * (a * cos_f), a * sin_f, d.y * (a * cos_f));
}

void vertex() {
	// Получаем мировые координаты для честных волн
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	vec3 tangent = vec3(1.0, 0.0, 0.0);
	vec3 binormal = vec3(0.0, 0.0, 1.0);
	vec3 p = world_pos;

	p += calculate_gerstner(wave_1, world_pos, tangent, binormal, TIME);
	p += calculate_gerstner(wave_2, world_pos, tangent, binormal, TIME);
	
	// Смещение от динамической ряби (опционально)
	vec2 ripple_uv = world_pos.xz / 50.0 + 0.5;
	float ripple = texture(ripple_texture, ripple_uv).r;
	p.y += ripple * 0.5;

	// Возвращаем в локальные координаты и передаем нормаль
	VERTEX = (inverse(MODEL_MATRIX) * vec4(p, 1.0)).xyz;
	NORMAL = normalize(cross(binormal, tangent));
}

void fragment() {
	// 1. ПРАВИЛЬНЫЙ WORLD-SPACE UV (Текстура больше не следует за камерой)
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 world_uv = world_pos.xz * 0.2; 
	vec2 motion = vec2(TIME * 0.02, TIME * 0.01);

	// 2. ГЛУБИНА (Depth Fade и Beer's Law)
	float depth_raw = texture(depth_tex, SCREEN_UV).r;
	// Исправление артефактов на горизонте (небо)
	if (depth_raw >= 1.0) depth_raw = 1000.0;
	
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	float water_depth = clamp(linear_depth + VERTEX.z, 0.0, 100.0);
	
	float depth_factor = exp(-water_depth * 1.2);
	float shore_mask = smoothstep(depth_distance, 0.0, water_depth);

	// 3. НОРМАЛИ (Смешивание слоев для детализации)
	vec3 n1 = texture(normal_map, world_uv + motion).rgb * 2.0 - 1.0;
	vec3 n2 = texture(normal_map, world_uv * 0.6 - motion * 0.4).rgb * 2.0 - 1.0;
	vec3 normal_mix = normalize(n1 + n2);

	// 4. ПЕНА (Foam)
	float noise = texture(foam_noise, world_uv + motion * 1.5).r;
	float foam_mask = smoothstep(0.2, 0.0, water_depth); // Порог у берега
	float foam_final = smoothstep(0.45, 0.55, foam_mask * noise) * foam_multiplier;

	// 5. ФИНАЛЬНЫЙ ЦВЕТ И ПРОЗРАЧНОСТЬ
	float fresnel = pow(1.0 - dot(NORMAL, VIEW), 4.0);
	vec3 base_color = mix(water_color, shallow_color, shore_mask);
	
	ALBEDO = mix(base_color, vec3(0.9), foam_final);
	
	// Эффект небольшого просвечивания (SSS) на гребнях
	if (NORMAL.y > 0.0) {
		ALBEDO += shallow_color * (1.0 - depth_factor) * 0.15;
	}

	METALLIC = 0.2;
	ROUGHNESS = 0.04;
	SPECULAR = 0.6;
	NORMAL = normalize(mix(NORMAL, normal_mix, 0.3));
	
	// Прозрачность: мелководье прозрачное, глубина и углы (Френель) — нет
	ALPHA = clamp(1.0 - depth_factor + fresnel + foam_final, 0.0, 1.0);
}
