class_name PuntajeEcologico
extends RefCounted
## Calcula la ficha educativa de una foto sin modificar los valores base de la especie.


static func calcular(especie: Especie, calidad: float, repetida: bool) -> Dictionary:
	var atributos := AtributosEcologicos.generar_atributos(especie, repetida)
	var calidad_clamped := clampf(calidad, 0.0, 1.0)
	var multiplicador_calidad := AtributosEcologicos.multiplicador_calidad(calidad_clamped)
	var factor_conservacion := especie.factor_conservacion_pb()
	return {
		"atributos": atributos,
		"calidad_foto": calidad_clamped,
		"multiplicador_calidad": multiplicador_calidad,
		"factor_conservacion": factor_conservacion,
		"puntos_biodiversidad": AtributosEcologicos.calcular_puntos(
			atributos, multiplicador_calidad, factor_conservacion),
	}
