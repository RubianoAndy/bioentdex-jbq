shader_type spatial;
render_mode unshaded;
// Pinta el suelo del humedal según la máscara de colores (mapa/mascara_humedal.png).
// Si cambias un color de la máscara aquí, cámbialo también en mapa/paleta_mapa.gd.

uniform sampler2D mascara : filter_nearest, repeat_disable;
uniform sampler2D ruido : filter_linear_mipmap, repeat_enable;
uniform vec2 tamano_mapa = vec2(160.0, 160.0);

// Colores de la máscara, tal como se pintan (0-255)
const vec3 MASCARA[13] = vec3[13](
	vec3(40.0, 90.0, 200.0),    // 0 agua
	vec3(40.0, 120.0, 60.0),    // 1 juncal
	vec3(120.0, 190.0, 80.0),   // 2 pasto
	vec3(20.0, 80.0, 40.0),     // 3 bosque
	vec3(160.0, 110.0, 60.0),   // 4 sendero
	vec3(220.0, 200.0, 90.0),   // 5 pradera
	vec3(130.0, 130.0, 130.0),  // 6 calle
	vec3(60.0, 160.0, 160.0),   // 7 plantas flotantes
	vec3(100.0, 70.0, 40.0),    // 8 tierra
	vec3(200.0, 160.0, 110.0),  // 9 puente de madera
	vec3(200.0, 60.0, 60.0),    // 10 manzana (casas)
	vec3(180.0, 190.0, 40.0),   // 11 kikuyo
	vec3(120.0, 100.0, 120.0)   // 12 basural
);

const vec2 DIRECCION_PUENTES = vec2(0.657, 0.754);   // las tablas van atravesadas a esta dirección

int clase(ivec2 px, ivec2 tam) {
	vec3 c = texelFetch(mascara, clamp(px, ivec2(0), tam - 1), 0).rgb * 255.0;
	int mejor = 2;
	float menor = 1e9;
	for (int k = 0; k < 13; k++) {
		vec3 d = c - MASCARA[k];
		float e = dot(d, d);
		if (e < menor) {
			menor = e;
			mejor = k;
		}
	}
	return mejor;
}

// Color de cada tipo de suelo, con su textura. nf = ruido fino, nm = ruido medio, ng = grano muy fino
vec3 color_suelo(int k, vec2 pos, float nf, float nm, float ng, float olas) {
	if (k == 0) {   // agua: oscura y verdosa, como la de los humedales de la sabana
		vec3 c = mix(vec3(0.12, 0.22, 0.23), vec3(0.17, 0.29, 0.27), nm);
		return c + vec3(0.2, 0.22, 0.22) * olas;
	}
	if (k == 7) {   // agua cubierta de buchón y lenteja de agua
		vec3 c = mix(vec3(0.13, 0.26, 0.17), vec3(0.32, 0.5, 0.2), smoothstep(0.42, 0.6, nf));
		return c * (0.85 + 0.3 * ng);
	}
	if (k == 1) {   // juncal: barro húmedo con brotes
		vec3 c = mix(vec3(0.2, 0.28, 0.14), vec3(0.29, 0.25, 0.15), smoothstep(0.45, 0.7, nm));
		return c * (0.8 + 0.35 * ng);
	}
	if (k == 2) {   // pasto
		vec3 c = mix(vec3(0.34, 0.52, 0.2), vec3(0.46, 0.62, 0.27), smoothstep(0.3, 0.7, nm));
		c *= 0.8 + 0.4 * ng;
		return mix(c, vec3(0.42, 0.45, 0.2), smoothstep(0.65, 0.8, nf) * 0.5);   // parches secos
	}
	if (k == 3) {   // ronda: suelo con sombra y hojarasca
		vec3 c = mix(vec3(0.17, 0.3, 0.14), vec3(0.3, 0.27, 0.16), smoothstep(0.5, 0.75, nf));
		return c * (0.8 + 0.35 * ng);
	}
	if (k == 4) {   // sendero de tierra con piedritas
		vec3 c = vec3(0.64, 0.53, 0.38) * (0.85 + 0.25 * nm);
		return mix(c, vec3(0.82, 0.76, 0.65), step(0.7, ng) * 0.5);
	}
	if (k == 5) {   // pradera con flores silvestres
		vec3 c = mix(vec3(0.5, 0.64, 0.28), vec3(0.6, 0.68, 0.32), nm) * (0.85 + 0.3 * ng);
		float flor = step(0.8, ng) * step(0.55, nf);
		return mix(c, mix(vec3(1.0, 0.9, 0.3), vec3(0.95, 0.95, 0.95), step(0.6, nm)), flor);
	}
	if (k == 6) {   // calle de asfalto
		return vec3(0.36, 0.36, 0.38) * (0.88 + 0.24 * ng);
	}
	if (k == 8) {   // tierra negra (compost)
		return vec3(0.27, 0.19, 0.12) * (0.75 + 0.5 * ng);
	}
	if (k == 9) {   // pasarela de tablas de madera
		float t = fract(dot(pos, DIRECCION_PUENTES) * 2.5);
		float junta = smoothstep(0.0, 0.08, t) * smoothstep(1.0, 0.92, t);
		return vec3(0.56, 0.39, 0.23) * (0.6 + 0.3 * junta + 0.15 * nf);
	}
	if (k == 10) {   // andén bajo las casas
		return vec3(0.62, 0.6, 0.56) * (0.9 + 0.2 * ng);
	}
	if (k == 11) {   // kikuyo alto e invasor: verde amarillento
		return mix(vec3(0.5, 0.56, 0.22), vec3(0.66, 0.65, 0.3), nf) * (0.85 + 0.3 * ng);
	}
	// 12 basural: tierra gris con papeles y plásticos
	vec3 c = vec3(0.4, 0.37, 0.32) * (0.85 + 0.3 * nm);
	float papel = step(0.75, ng) * step(0.4, nf);
	return mix(c, mix(vec3(0.92, 0.92, 0.88), vec3(0.3, 0.5, 0.85), step(0.5, nm)), papel * 0.8);
}

bool es_agua(int k) {
	return k == 0 || k == 7;
}

void fragment() {
	ivec2 tam = textureSize(mascara, 0);
	vec2 pos = (UV - 0.5) * tamano_mapa;

	// Se deforma un poco la lectura de la máscara con ruido para que los bordes no queden en escalera
	vec2 deformacion = vec2(texture(ruido, pos * 0.15).r, texture(ruido, pos * 0.15 + vec2(0.37, 0.71)).r) - 0.5;
	vec2 p = UV * vec2(tam) - 0.5 + deformacion * 2.5;
	ivec2 i = ivec2(floor(p));
	vec2 f = fract(p);

	float nf = texture(ruido, pos * 0.9).r;
	float nm = texture(ruido, pos * 0.08).r;
	float ng = texture(ruido, pos * 3.1).r;
	float o1 = texture(ruido, pos * 0.09 + vec2(TIME * 0.012, TIME * 0.007)).r;
	float o2 = texture(ruido, pos * 0.13 - vec2(TIME * 0.009, -TIME * 0.011)).r;
	float olas = smoothstep(0.58, 0.72, (o1 + o2) * 0.5);

	int k00 = clase(i, tam);
	int k10 = clase(i + ivec2(1, 0), tam);
	int k01 = clase(i + ivec2(0, 1), tam);
	int k11 = clase(i + ivec2(1, 1), tam);
	vec3 color = mix(
		mix(color_suelo(k00, pos, nf, nm, ng, olas), color_suelo(k10, pos, nf, nm, ng, olas), f.x),
		mix(color_suelo(k01, pos, nf, nm, ng, olas), color_suelo(k11, pos, nf, nm, ng, olas), f.x), f.y);

	// Orilla: barro húmedo donde el agua se encuentra con la tierra
	float agua = mix(mix(float(es_agua(k00)), float(es_agua(k10)), f.x),
			mix(float(es_agua(k01)), float(es_agua(k11)), f.x), f.y);
	color = mix(color, vec3(0.26, 0.22, 0.15) * (0.85 + 0.3 * ng), 4.0 * agua * (1.0 - agua) * 0.7);

	// Sombras de nubes que pasan despacio sobre el humedal
	float nube = texture(ruido, pos * 0.012 + vec2(TIME * 0.004, TIME * 0.0025)).r;
	color *= 1.0 - 0.2 * smoothstep(0.5, 0.68, nube);

	ALBEDO = pow(color, vec3(2.2));   // los colores de arriba están en sRGB
}
