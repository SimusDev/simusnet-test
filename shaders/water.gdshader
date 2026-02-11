shader_type spatial;

// Настройки отрисовки
render_mode cull_disabled, depth_draw_always, diffuse_lambert, specular_schlick_ggx;

group_uniforms Base_Water;
uniform vec3 water_color : source_color = vec3(0.01, 0.1, 0.2);
uniform vec3 shallow_color : source_color = vec3(0.1, 0.4, 0.4);
uniform float alpha : hint_range(0.0, 1.0) = 0.75;
uniform float refraction_strength : hint_range(0.0, 1.0) = 0.05;
uniform float depth_distance : hint_range(0.1, 10.0) = 2.0;

group_uniforms Waves_Physical;
uniform vec4 wave_1 = vec4(1.0, 0.0, 0.1, 5.0); 
uniform vec4 wave_2 = vec4(0.7, 0.7, 0.05, 2.5);
uniform float wave_speed = 1.0;

group_uniforms Textures_and_Effects;
uniform sampler2D normal_map : hint_normal, repeat_enable;
uniform sampler2D foam_noise : hint_default_white, repeat_enable;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_tex : hint_depth_texture;

varying float v_depth_offset; // Передаем высоту волны для корректной глубины

vec3 calculate_gerstner(vec4 wave, vec3 p, inout vec3 tangent, inout vec3 binormal, float time) {
	float k = 2.0 * PI / wave.w;
	float f = k * (dot(normalize(wave.xz), p.xz) - (sqrt(9.8 / k) * time * wave_speed));
	float a = wave.y / k;
	vec2 d = normalize(wave.xz);

	tangent += vec3(-d.x * d.x * (wave.y * sin(f)), d.x * (wave.y * cos(f)), -d.x * d.y * (wave.y * sin(f)));
	binormal += vec3(-d.x * d.y * (wave.y * sin(f)), d.y * (wave.y * cos(f)), -d.y * d.y * (wave.y * sin(f)));

	return vec3(d.x * (a * cos(f)), a * sin(f), d.y * (a * cos(f)));
}

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 tangent = vec3(1.0, 0.0, 0.0);
	vec3 binormal = vec3(0.0, 0.0, 1.0);
	
	vec3 p = world_pos;
	p += calculate_gerstner(wave_1, world_pos, tangent, binormal, TIME);
	p += calculate_gerstner(wave_2, world_pos, tangent, binormal, TIME);
	
	v_depth_offset = p.y - world_pos.y; // Запоминаем смещение волны
	VERTEX = (inverse(MODEL_MATRIX) * vec4(p, 1.0)).xyz;
	NORMAL = normalize(cross(binormal, tangent));
}

void fragment() {
	// 1. Координаты и нормали (базис TBN)
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 world_uv = world_pos.xz * 0.1; 
	vec2 motion = vec2(TIME * 0.02, TIME * 0.01);

	vec3 n1 = texture(normal_map, world_uv + motion).rgb * 2.0 - 1.0;
	vec3 n2 = texture(normal_map, world_uv * 0.5 - motion * 0.2).rgb * 2.0 - 1.0;
	vec3 local_normal = normalize(n1 + n2);
	vec3 world_normal = normalize(local_normal.x * TANGENT + local_normal.y * BINORMAL + local_normal.z * NORMAL);

	// 2. Глубина
	float depth_raw = texture(depth_tex, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw);
	vec4 view_coords = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view_coords.xyz /= view_coords.w;
	float water_depth = -view_coords.z + VERTEX.z;
	water_depth = max(water_depth, 0.0);

	// 3. Преломление (Refraction)
	vec2 ref_uv = SCREEN_UV + (world_normal.xz * refraction_strength) / (1.0 + water_depth);
	float depth_check = texture(depth_tex, ref_uv).r;
	if (depth_check < depth_raw) ref_uv = SCREEN_UV;
	vec3 screen_color = texture(screen_tex, ref_uv).rgb;

	// 4. Цветовая модель (Улучшенная яркость)
	float depth_factor = exp(-water_depth / depth_distance);
	
	// Смешиваем цвета воды
	vec3 water_tint = mix(water_color, shallow_color, depth_factor);
	
	// Имитация рассеивания света (чтобы вода не была черной дырой)
	// Добавляем немного shallow_color в глубокие места как "внутренний свет"
	vec3 sss_effect = shallow_color * (1.0 - depth_factor) * 0.2;
	
	// Смешивание с дном: используем SCREEN как базу, но не гасим её слишком сильно
	vec3 color_with_depth = mix(water_tint, screen_color * (water_tint + 0.5), depth_factor);
	vec3 final_color = color_with_depth + sss_effect;

	// 5. Френель (отражение неба)
	// Поскольку GI нет, френель должен имитировать отражение купола неба
	float fresnel = pow(1.0 - clamp(dot(world_normal, VIEW), 0.0, 1.0), 4.0);
	vec3 sky_reflection = shallow_color * 0.5; // Имитируем голубое отражение
	final_color = mix(final_color, sky_reflection, fresnel * 0.6);

	// 6. Финальные параметры
	ALBEDO = final_color;
	
	// Блики (Specular) — единственный источник "яркости" без GI
	METALLIC = 0.1;
	ROUGHNESS = 0.08; 
	SPECULAR = 1.0; // Максимальный блик от солнца
	NORMAL = world_normal;
	
	// Пена
	float foam_noise_val = texture(foam_noise, world_uv + motion * 1.5).r;
	float foam_mask = smoothstep(0.15, 0.0, water_depth);
	float foam = smoothstep(0.4, 0.6, foam_mask + foam_noise_val * 0.4);
	ALBEDO = mix(ALBEDO, vec3(0.9), foam);

	// Плавный край у берега
	float edge_fade = smoothstep(0.0, 0.05, water_depth);
	ALPHA = clamp(edge_fade, 0.0, alpha);
}

