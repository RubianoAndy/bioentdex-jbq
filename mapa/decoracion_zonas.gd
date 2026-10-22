class_name DecoracionZonas
## Objetos propios de algunas zonas: mirador de aves, monolitos, composteras y basura.
## Para decorar otra zona, agrega un caso con su id en decorar().


static func decorar(padre: Node3D, zonas: Array, terreno: Terreno) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for zona in zonas:
		var centro: Vector2 = zona.posicion
		match zona.id:
			"avistamiento_aves":
				# El mirador queda al lado del punto de la zona (no al sur, para no tapar la cámara)
				_poner(padre, terreno, "mirador", centro + Vector2(3.2, -0.6), 0.0, 1.7)
			"monolitos":
				for i in 7:
					var angulo := TAU * i / 7.0
					var pos := centro + Vector2.from_angle(angulo) * 3.2
					_poner(padre, terreno, "monolito", pos, -angulo, 0.45, rng.randf_range(0.8, 1.25))
			"materia_organica":
				for i in 3:
					for j in 2:
						_poner(padre, terreno, "compostera", centro + Vector2(-2.0 + i * 2.0, -3.2 + j * 1.6), 0.0, 0.9)
			"basuras":
				for i in 30:
					var pos := centro + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(1.0, 5.0)
					var modelo := "llanta" if i % 5 == 0 else "basura"
					var objeto := _poner(padre, terreno, modelo, pos, rng.randf() * TAU, 0.0, rng.randf_range(0.8, 1.4))
					if modelo == "basura":
						objeto.material_override = _color_basura(rng)


## Pone un objeto en el mapa y, si radio > 0, lo marca como obstáculo.
static func _poner(padre: Node3D, terreno: Terreno, modelo: String, pos: Vector2, giro: float,
		radio: float, escala := 1.0) -> MeshInstance3D:
	var objeto := MeshInstance3D.new()
	objeto.mesh = ModelosMapa.crear(modelo)
	objeto.transform = Transform3D(Basis(Vector3.UP, giro).scaled(Vector3.ONE * escala), Vector3(pos.x, 0, pos.y))
	objeto.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(objeto)
	if radio > 0.0:
		terreno.bloquear_circulo(pos, radio * escala)
	return objeto


static func _color_basura(rng: RandomNumberGenerator) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = [Color(0.1, 0.1, 0.1), Color(0.95, 0.95, 0.95), Color(0.2, 0.4, 0.85)][rng.randi() % 3]
	return mat
