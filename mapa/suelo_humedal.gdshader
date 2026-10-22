shader_type spatial;
render_mode unshaded;
// Pinta el suelo del humedal según la máscara de colores (mapa/mascara_humedal.png).
// Si cambias un color de la máscara aquí, cámbialo también en mapa/paleta_mapa.gd.

uniform sampler2D mascara : filter_nearest, repeat_disable;
uniform sampler2D ruido : filter_linear_mipmap, repeat_enable;
uniform vec2 tamano_mapa = vec2(120.0, 120.0);

// Colores de la máscara, tal como se pintan (0-255)
const vec3 MASCARA[9] = vec3[9](
	vec3(40.0, 90.0, 200.0),    // 0 agua
	vec3(40.0, 120.0, 60.0),    // 1 juncal
	vec3(120.0, 190.0, 80.0),   // 2 pasto
	vec3(20.0, 80.0, 40.0),     // 3 bosque
	vec3(160.0, 110.0, 60.0),   // 4 sendero
	vec3(220.0, 200.0, 90.0),   // 5 pradera
	vec3(130.0, 130.0, 130.0),  // 6 ciudad
	vec3(60.0, 160.0, 160.0),   // 7 plantas flotantes
	vec3(100.0, 70.0, 40.0)     // 8 tierra (camellones)
);

// Color con el que se ve cada zona en el juego
const vec3 SUELO[9] = vec3[9](
	vec3(0.16, 0.42, 0.62),
	vec3(0.30, 0.45, 0.24),
	vec3(0.45, 0.68, 0.32),
	vec3(0.24, 0.44, 0.22),
	vec3(0.74, 0.60, 0.40),
	vec3(0.78, 0.74, 0.40),
	vec3(0.56, 0.56, 0.58),
	vec3(0.18, 0.44, 0.42),
	vec3(0.44, 0.31, 0.19)
);

int clase(ivec2 px, ivec2 tam) {
	vec3 c = texelFetch(mascara, clamp(px, ivec2(0), tam - 1), 0).rgb * 255.0;
	int mejor = 2;
	float menor = 1e9;
	for (int k = 0; k < 9; k++) {
		vec3 d = c - MASCARA[k];
		float e = dot(d, d);
		if (e < menor) {
			menor = e;
			mejor = k;
		}
	}
	return mejor;
}

void fragment() {
	ivec2 tam = textureSize(mascara, 0);
	vec2 pos = (UV - 0.5) * tamano_mapa;
	// Se deforma un poco la lectura de la máscara con ruido para que los bordes no queden en escalera
	vec2 deformacion = vec2(texture(ruido, pos * 0.15).r, texture(ruido, pos * 0.15 + vec2(0.37, 0.71)).r) - 0.5;
	vec2 p = UV * vec2(tam) - 0.5 + deformacion * 2.5;
	ivec2 i = ivec2(floor(p));
	vec2 f = fract(p);

	int k00 = clase(i, tam);
	int k10 = clase(i + ivec2(1, 0), tam);
	int k01 = clase(i + ivec2(0, 1), tam);
	int k11 = clase(i + ivec2(1, 1), tam);
	vec3 color = mix(mix(SUELO[k00], SUELO[k10], f.x), mix(SUELO[k01], SUELO[k11], f.x), f.y);

	// Cuánta agua hay en este punto (para los brillos)
	float agua = mix(mix(float(k00 == 0 || k00 == 7), float(k10 == 0 || k10 == 7), f.x),
			mix(float(k01 == 0 || k01 == 7), float(k11 == 0 || k11 == 7), f.x), f.y);

	float n =texture(ruido, pos * 0.06).r;
	color *= 0.86 + 0.28 * n;   // variación para que no se vea plano

	float o1 = texture(ruido, pos * 0.09 + vec2(TIME * 0.012, TIME * 0.007)).r;
	float o2 = texture(ruido, pos * 0.13 - vec2(TIME * 0.009, -TIME * 0.011)).r;
	color += vec3(0.16, 0.2, 0.22) * smoothstep(0.58, 0.72, (o1 + o2) * 0.5) * agua;

	ALBEDO = pow(color, vec3(2.2));   // los colores de arriba están en sRGB
}
