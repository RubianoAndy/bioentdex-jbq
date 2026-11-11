extends Node3D
## Prado seco de duelo, rodeado de vegetación y luces de humedal.

const COLORES_FLORES: Array[Color] = [
	Color(1.0, 0.76, 0.26),
	Color(0.94, 0.43, 0.57),
	Color(0.66, 0.56, 1.0),
	Color(0.96, 0.9, 0.68),
]

var _material_prado: StandardMaterial3D
var _material_tallo: StandardMaterial3D
var _material_hoja: StandardMaterial3D
var _material_piedra: StandardMaterial3D
var _material_semilla: StandardMaterial3D
var _materiales_flores: Array[StandardMaterial3D] = []
var _luces: Array[MeshInstance3D] = []
var _posiciones_luces: Array[Vector3] = []
var _fases_luces: Array[float] = []
var _tiempo := 0.0


func _ready() -> void:
	_material_prado = _crear_material(Color(0.32, 0.56, 0.29))
	_material_tallo = _crear_material(Color(0.19, 0.4, 0.22))
	_material_hoja = _crear_material(Color(0.39, 0.67, 0.3))
	_material_piedra = _crear_material(Color(0.55, 0.49, 0.38))
	_material_semilla = _crear_material(Color(1.0, 0.87, 0.38))
	for color in COLORES_FLORES:
		_materiales_flores.append(_crear_material(color))
	_crear_prado_central()
	_decorar_borde()
	_crear_luciernagas()


func _process(delta: float) -> void:
	_tiempo += delta
	for indice in _luces.size():
		_luces[indice].position.y = _posiciones_luces[indice].y \
			+ sin(_tiempo * 1.5 + _fases_luces[indice]) * 0.12


func _crear_prado_central() -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 5.4
	mesh.bottom_radius = 5.6
	mesh.height = 0.16
	mesh.radial_segments = 40
	var prado := MeshInstance3D.new()
	prado.name = "PradoSeco"
	prado.mesh = mesh
	prado.material_override = _material_prado
	prado.position.y = -0.015
	prado.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(prado)


func _decorar_borde() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for indice in range(24):
		var angulo := TAU * float(indice) / 24.0 + rng.randf_range(-0.08, 0.08)
		var radio := rng.randf_range(6.2, 8.5)
		var posicion := Vector3(cos(angulo) * radio, -0.08, sin(angulo) * radio)
		match indice % 4:
			0:
				_crear_juncos(posicion, rng)
			1:
				_crear_arbusto(posicion, rng)
			_:
				_crear_flor(posicion, _materiales_flores[rng.randi_range(0, _materiales_flores.size() - 1)],
					rng.randf_range(0.75, 1.15))
		_crear_piedra(posicion + Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.35, 0.35)),
			rng.randf_range(0.65, 1.1))


func _crear_flor(posicion: Vector3, material_petalo: Material, escala: float) -> void:
	var flor := Node3D.new()
	flor.position = posicion
	add_child(flor)
	var tallo := CylinderMesh.new()
	tallo.top_radius = 0.018
	tallo.bottom_radius = 0.04
	tallo.height = 0.56 * escala
	_agregar_malla(flor, tallo, _material_tallo, Vector3(0, 0.28 * escala, 0))

	var centro_y := 0.58 * escala
	for indice in range(5):
		var angulo := TAU * float(indice) / 5.0
		var petalo := SphereMesh.new()
		petalo.radius = 0.12 * escala
		petalo.height = 0.2 * escala
		petalo.radial_segments = 6
		petalo.rings = 3
		_agregar_malla(flor, petalo, material_petalo,
			Vector3(cos(angulo) * 0.1 * escala, centro_y, sin(angulo) * 0.1 * escala),
			Vector3(1.0, 0.65, 0.9))

	var semilla := SphereMesh.new()
	semilla.radius = 0.07 * escala
	semilla.height = 0.14 * escala
	semilla.radial_segments = 6
	semilla.rings = 3
	_agregar_malla(flor, semilla, _material_semilla, Vector3(0, centro_y + 0.02, 0))


func _crear_juncos(posicion: Vector3, rng: RandomNumberGenerator) -> void:
	var grupo := Node3D.new()
	grupo.position = posicion
	add_child(grupo)
	for indice in range(3):
		var altura := rng.randf_range(0.75, 1.35)
		var desplazamiento := Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.2, 0.2))
		var tallo := CylinderMesh.new()
		tallo.top_radius = 0.018
		tallo.bottom_radius = 0.04
		tallo.height = altura
		_agregar_malla(grupo, tallo, _material_tallo,
			desplazamiento + Vector3(0, altura * 0.5, 0))
		var hoja := SphereMesh.new()
		hoja.radius = 0.13
		hoja.height = altura * 0.55
		hoja.radial_segments = 6
		hoja.rings = 3
		var instancia := _agregar_malla(grupo, hoja, _material_hoja,
			desplazamiento + Vector3(rng.randf_range(-0.12, 0.12), altura * 0.72, 0))
		instancia.rotation.z = rng.randf_range(-0.5, 0.5)
		instancia.scale = Vector3(0.55, 1.0, 0.45)


func _crear_arbusto(posicion: Vector3, rng: RandomNumberGenerator) -> void:
	var grupo := Node3D.new()
	grupo.position = posicion
	add_child(grupo)
	for indice in range(3):
		var mata := SphereMesh.new()
		mata.radius = rng.randf_range(0.3, 0.42)
		mata.height = rng.randf_range(0.45, 0.65)
		mata.radial_segments = 6
		mata.rings = 3
		_agregar_malla(grupo, mata, _material_hoja,
			Vector3((indice - 1) * 0.28, 0.24, rng.randf_range(-0.12, 0.12)))


func _crear_piedra(posicion: Vector3, escala: float) -> void:
	var roca := SphereMesh.new()
	roca.radius = 0.3 * escala
	roca.height = 0.34 * escala
	roca.radial_segments = 6
	roca.rings = 3
	_agregar_malla(self, roca, _material_piedra, posicion + Vector3(0, 0.04, 0),
		Vector3(1.3, 0.55, 0.9))


func _crear_luciernagas() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var brillo := _crear_material(Color(0.72, 1.0, 0.48), true)
	for indice in range(10):
		var angulo := rng.randf_range(0.0, TAU)
		var radio := rng.randf_range(4.5, 8.0)
		var posicion := Vector3(cos(angulo) * radio, rng.randf_range(0.8, 1.8),
			sin(angulo) * radio)
		var mesh := SphereMesh.new()
		mesh.radius = 0.055
		mesh.height = 0.11
		mesh.radial_segments = 6
		mesh.rings = 3
		var luz := _agregar_malla(self, mesh, brillo, posicion)
		_luces.append(luz)
		_posiciones_luces.append(posicion)
		_fases_luces.append(rng.randf_range(0.0, TAU))


func _agregar_malla(padre: Node3D, mesh: Mesh, material: Material, posicion: Vector3,
		escala: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var instancia := MeshInstance3D.new()
	instancia.mesh = mesh
	instancia.material_override = material
	instancia.position = posicion
	instancia.scale = escala
	instancia.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	padre.add_child(instancia)
	return instancia


func _crear_material(color: Color, emitir_luz := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	if emitir_luz:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.emission_enabled = true
		material.emission = color
	return material
