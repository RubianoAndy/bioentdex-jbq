shader_type canvas_item;
// Nubes suaves que se mueven despacio (se dibujan sobre un ColorRect).
// "ruido" debe ser un NoiseTexture2D sin costuras (seamless).

uniform sampler2D ruido : repeat_enable, filter_linear_mipmap;
uniform float velocidad = 0.006;
uniform float cobertura : hint_range(0.0, 1.0) = 0.52;   // más alto = menos nubes
uniform float suavidad : hint_range(0.01, 0.5) = 0.18;
uniform float opacidad : hint_range(0.0, 1.0) = 0.9;
uniform vec2 escala = vec2(1.0, 1.6);
uniform float limite_inferior : hint_range(0.0, 1.0) = 1.0;   // las nubes se desvanecen hacia abajo
uniform vec4 color_luz : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 color_sombra : source_color = vec4(0.72, 0.77, 0.84, 1.0);

void fragment() {
	vec2 uv = UV * escala;
	float t = TIME * velocidad;
	float n = texture(ruido, uv + vec2(t, 0.0)).r * 0.6
		+ texture(ruido, uv * 2.3 + vec2(t * 1.7, 0.31)).r * 0.28
		+ texture(ruido, uv * 5.1 + vec2(t * 2.6, 0.73)).r * 0.12;
	float alfa = smoothstep(cobertura, cobertura + suavidad, n);
	// Parte de arriba de la nube iluminada, parte de abajo en sombra
	float luz = smoothstep(cobertura, cobertura + 0.35, texture(ruido, uv + vec2(t, -0.02)).r * 0.6 + n * 0.4);
	vec3 color = mix(color_sombra.rgb, color_luz.rgb, luz);
	alfa *= 1.0 - smoothstep(limite_inferior - 0.2, limite_inferior, UV.y);
	COLOR = vec4(color, alfa * opacidad);
}
