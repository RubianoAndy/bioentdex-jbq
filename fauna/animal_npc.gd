extends Node3D
## Animal NPC (aves, ranas, mamíferos, lombrices...): vive en su zona y se mueve según su especie.
## No se captura: al tocarlo se abre su ficha y queda registrado como observado.

var especie: Especie
var terreno: Terreno
var centro := Vector2.ZERO     # centro del área donde se mueve
var radio := 8.0

var _sprite: Sprite3D
var _alto := 1.0
var _objetivo := Vector3.ZERO
var _espera := 0.0
var _tiempo := randf() * TAU
var _salto := -1.0             # progreso del salto (0..1), -1 si no está saltando
var _salto_desde := Vector3.ZERO


func configurar(nueva_especie: Especie, nuevo_terreno: Terreno, area_centro: Vector2, area_radio: float, pos: Vector2) -> void:
	especie = nueva_especie
	terreno = nuevo_terreno
	centro = area_centro
	radio = area_radio
	position = Vector3(pos.x, 0, pos.y)
	_objetivo = position


func _ready() -> void:
	var textura := especie.imagen_mapa()
	_sprite = Sprite3D.new()
	_sprite.texture = textura
	_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	if textura:
		_sprite.pixel_size = especie.tamano_en_mapa / maxf(textura.get_width(), textura.get_height())
		_alto = textura.get_height() * _sprite.pixel_size
	add_child(_sprite)

	var sombra := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = especie.tamano_en_mapa * 0.3
	disco.bottom_radius = disco.top_radius
	disco.height = 0.01
	sombra.mesh = disco
	sombra.position.y = 0.02
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0, 0, 0, 0.3)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sombra.material_override = mat
	add_child(sombra)

	var area := Area3D.new()
	var forma := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = maxf(0.7, especie.tamano_en_mapa * 0.6)
	forma.shape = esfera
	forma.position.y = _alto * 0.5
	area.add_child(forma)
	add_child(area)
	_espera = randf_range(0.5, 3.0)


func _process(delta: float) -> void:
	_tiempo += delta
	var base_y := _alto * 0.5
	match especie.movimiento:
		Especie.Movimiento.NADAR:
			_deambular(delta, 0.7, [PaletaMapa.AGUA, PaletaMapa.FLOTANTES])
			base_y -= _alto * 0.2 - sin(_tiempo * 2.0) * 0.04   # medio cuerpo en el agua, flotando
		Especie.Movimiento.CAMINAR:
			var camina := _deambular(delta, 1.1, [])
			if camina:
				base_y += absf(sin(_tiempo * 9.0)) * 0.06
		Especie.Movimiento.SALTAR:
			base_y += _saltar(delta)
		_:
			base_y += sin(_tiempo * 1.5) * 0.02
	_sprite.position.y = base_y


## Camina hacia puntos al azar de su área, con pausas. Devuelve true mientras se mueve.
func _deambular(delta: float, velocidad: float, suelos: Array) -> bool:
	if _espera > 0.0:
		_espera -= delta
		return false
	var hacia := _objetivo - position
	if hacia.length() < 0.1:
		_espera = randf_range(1.5, 5.0)
		_objetivo = _punto_cercano(4.0, suelos)
		return false
	position += hacia.limit_length(velocidad * delta)
	if absf(hacia.x) > 0.05:
		_sprite.flip_h = hacia.x < 0.0   # las imágenes miran a la derecha
	return true


## Saltos cortos (ranas). Devuelve la altura del salto.
func _saltar(delta: float) -> float:
	if _salto < 0.0:
		_espera -= delta
		if _espera <= 0.0:
			_salto = 0.0
			_salto_desde = position
			_objetivo = _punto_cercano(1.8, [])
			_sprite.flip_h = _objetivo.x < position.x
		return 0.0
	_salto = minf(1.0, _salto + delta / 0.5)
	position = _salto_desde.lerp(_objetivo, _salto)
	if _salto >= 1.0:
		_salto = -1.0
		_espera = randf_range(1.0, 3.5)
	return sin(_salto * PI) * 0.7


## Punto al azar cerca de él, dentro de su área y en su tipo de suelo (o caminable, si no se indica).
func _punto_cercano(distancia: float, suelos: Array) -> Vector3:
	var suelos_validos: Array = suelos if not suelos.is_empty() else Array(especie.suelos_habitat)
	for intento in 12:
		var p := Vector2(position.x, position.z) + Vector2.from_angle(randf() * TAU) * randf_range(0.5, distancia)
		if p.distance_to(centro) > radio:
			continue
		var clase := terreno.clase_en(p)
		if clase in suelos_validos or (suelos_validos.is_empty() and terreno.transitable(p)):
			return Vector3(p.x, 0, p.y)
	return position


func al_tocar(_quien: Node3D) -> void:
	get_parent().npc_tocado(especie)
