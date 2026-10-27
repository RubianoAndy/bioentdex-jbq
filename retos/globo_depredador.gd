extends Node3D
## Globo de la "banda de depredadores": baja del cielo con un depredador del humedal en la canasta
## y su cara pintada en la tela. Al tocarlo (de cerca) empieza la batalla de preguntas.

const COLOR_TELA := Color(0.46, 0.1, 0.2)
const COLOR_FRANJA := Color(0.12, 0.08, 0.1)
const ROJO := Color(0.95, 0.25, 0.3)
const ALTURA_INICIAL := 18.0
const ALTO_CANASTA := 1.5

var depredador: Especie
var premio: Especie
var vida := 180.0          # segundos que se queda en el mapa
var _tiempo := 0.0
var _aterrizado := false
var _vuelo: Node3D         # todo lo que baja del cielo (tela, canasta y depredador)
var _anillo: MeshInstance3D
var _sombra: MeshInstance3D


func configurar(nuevo_depredador: Especie, nuevo_premio: Especie, pos: Vector2, duracion: float) -> void:
	depredador = nuevo_depredador
	premio = nuevo_premio
	vida = duracion
	position = Vector3(pos.x, 0, pos.y)


func _ready() -> void:
	_vuelo = Node3D.new()
	add_child(_vuelo)

	# Tela del globo con una franja oscura y la cara del depredador al frente (mirando a la cámara)
	var tela := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 1.15
	esfera.height = 2.7
	tela.mesh = esfera
	tela.position.y = ALTO_CANASTA + 2.3
	tela.material_override = _material(COLOR_TELA, false)
	_vuelo.add_child(tela)
	var franja := MeshInstance3D.new()
	var cinta := CylinderMesh.new()
	cinta.top_radius = 1.17
	cinta.bottom_radius = 1.17
	cinta.height = 0.3
	franja.mesh = cinta
	franja.position.y = tela.position.y - 0.2
	franja.material_override = _material(COLOR_FRANJA, false)
	_vuelo.add_child(franja)

	var textura := depredador.imagen_mapa()
	if textura:
		var emblema := Sprite3D.new()
		emblema.texture = textura
		emblema.pixel_size = 1.2 / maxf(textura.get_width(), textura.get_height())
		emblema.position = Vector3(0, tela.position.y + 0.15, 1.17)
		emblema.modulate = Color(1, 0.85, 0.85)
		_vuelo.add_child(emblema)

	# Canasta, cuerdas y el depredador asomado
	var canasta := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(0.9, 0.5, 0.9)
	canasta.mesh = caja
	canasta.position.y = ALTO_CANASTA
	canasta.material_override = _material(Color(0.5, 0.33, 0.18), false)
	_vuelo.add_child(canasta)
	for esquina in [Vector2(0.4, 0.4), Vector2(-0.4, 0.4), Vector2(0.4, -0.4), Vector2(-0.4, -0.4)]:
		var cuerda := MeshInstance3D.new()
		var hilo := CylinderMesh.new()
		hilo.top_radius = 0.02
		hilo.bottom_radius = 0.02
		hilo.height = 1.0
		hilo.radial_segments = 4
		cuerda.mesh = hilo
		cuerda.position = Vector3(esquina.x, ALTO_CANASTA + 0.7, esquina.y)
		cuerda.material_override = _material(COLOR_FRANJA, true)
		_vuelo.add_child(cuerda)
	if textura:
		var pasajero := Sprite3D.new()
		pasajero.texture = textura
		pasajero.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		pasajero.pixel_size = 1.0 / maxf(textura.get_width(), textura.get_height())
		pasajero.position.y = ALTO_CANASTA + 0.55
		_vuelo.add_child(pasajero)

	var alerta := Label3D.new()
	alerta.text = "!"
	alerta.font_size = 120
	alerta.outline_size = 24
	alerta.modulate = ROJO
	alerta.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	alerta.pixel_size = 0.01
	alerta.position.y = ALTO_CANASTA + 4.2
	_vuelo.add_child(alerta)

	# En el suelo: sombra (crece al bajar) y anillo rojo que aparece al aterrizar
	_sombra = MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = 1.1
	disco.bottom_radius = 1.1
	disco.height = 0.01
	_sombra.mesh = disco
	_sombra.position.y = 0.02
	_sombra.material_override = _material(Color(0, 0, 0, 0.3), true)
	add_child(_sombra)
	_anillo = MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 1.25
	toro.outer_radius = 1.45
	toro.rings = 32
	toro.ring_segments = 6
	_anillo.mesh = toro
	_anillo.position.y = 0.05
	_anillo.material_override = _material(ROJO, true)
	_anillo.visible = false
	add_child(_anillo)

	var area := Area3D.new()
	var forma := CollisionShape3D.new()
	var cilindro := CylinderShape3D.new()
	cilindro.radius = 1.5
	cilindro.height = 6.0
	forma.shape = cilindro
	forma.position.y = 3.0
	area.add_child(forma)
	add_child(area)

	# Baja del cielo despacio
	_vuelo.position.y = ALTURA_INICIAL
	var bajada := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	bajada.tween_property(_vuelo, "position:y", 0.0, 4.0)
	bajada.tween_callback(func() -> void:
		_aterrizado = true
		_anillo.visible = true)


func _process(delta: float) -> void:
	_tiempo += delta
	if _aterrizado:
		_vuelo.position.y = sin(_tiempo * 1.6) * 0.12   # flota sobre el suelo
		var pulso := 1.0 + sin(_tiempo * 4.0) * 0.07
		_anillo.scale = Vector3(pulso, 1, pulso)
	var cerca := 1.0 - clampf(_vuelo.position.y / ALTURA_INICIAL, 0.0, 1.0)
	_sombra.scale = Vector3.ONE * lerpf(0.3, 1.0, cerca)


func al_tocar(_quien: Node3D) -> void:
	get_parent().globo_tocado(self)


## Se va volando (al terminar la batalla o si pasa el tiempo).
func desaparecer() -> void:
	_anillo.visible = false
	_aterrizado = false
	var subida := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	subida.tween_property(_vuelo, "position:y", ALTURA_INICIAL, 2.5)
	subida.tween_callback(queue_free)


func _material(color: Color, sin_luz: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if sin_luz:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat
