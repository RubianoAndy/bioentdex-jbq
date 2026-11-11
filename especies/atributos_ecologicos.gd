class_name AtributosEcologicos
extends RefCounted
## Cálculos de atributos y puntos de biodiversidad de cada captura.

const VARIACION_MINIMA := 0.95
const VARIACION_MAXIMA := 1.05
const MULTIPLICADOR_CALIDAD_MINIMO := 0.9
const MULTIPLICADOR_CALIDAD_MAXIMO := 1.1


static func generar_atributos(especie: Especie, repetida: bool,
		rng: RandomNumberGenerator = null) -> Dictionary:
	var atributos := {
		"ia": especie.impacto_ecologico,
		"rh": especie.resistencia_habitat,
		"vp": especie.vitalidad_poblacional,
	}
	if not repetida:
		return atributos

	for clave in atributos:
		var variacion := randf_range(VARIACION_MINIMA, VARIACION_MAXIMA) if rng == null \
			else rng.randf_range(VARIACION_MINIMA, VARIACION_MAXIMA)
		atributos[clave] = snappedf(clampf(float(atributos[clave]) * variacion, 0.0, 100.0), 0.1)
	return atributos


static func multiplicador_calidad(calidad: float) -> float:
	return lerpf(MULTIPLICADOR_CALIDAD_MINIMO, MULTIPLICADOR_CALIDAD_MAXIMO, clampf(calidad, 0.0, 1.0))


static func calcular_puntos(atributos: Dictionary, multiplicador: float,
		factor_conservacion: float = 1.0) -> int:
	var promedio := (float(atributos.ia) + float(atributos.rh) + float(atributos.vp)) / 3.0
	return roundi(promedio * multiplicador * factor_conservacion)
