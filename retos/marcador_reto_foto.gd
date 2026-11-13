extends Node3D
## Reto de foto en el mapa: una cámara azul que flota sobre un anillo. Al tocarla (de cerca) se
## abre la cámara del teléfono para cumplir el reto; la foto queda en la base de datos.

const ICONO_CAMARA := preload("res://ui/icono_camara.svg")
const AZUL := Color(0.3, 0.7, 1.0)

var mision: Mision
var zona_id := ""
var vida := 180.0          # segundos que se queda en el mapa
var _tiempo := randf() * TAU
var _icono: Sprite3D
var _anillo: MeshInstance3D


func configurar(nueva_mision: Mision, nueva_zona_id: String, pos: Vector2, duracion: float) -> void:
	mision = nueva_mision
	zona_id = nueva_zona_id
	vida = duracion
	position = Vector3(pos.x, 0, pos.y)


func _ready() -> void:
	var halo := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = 0.95
	disco.bottom_radius = 0.95
	disco.height = 0.01
	halo.mesh = disco
	halo.position.y = 0.03
	halo.material_override = _material(Color(AZUL, 0.25))
	add_child(halo)

	_anillo = MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 0.8
	toro.outer_radius = 0.98
	toro.rings = 24
	toro.ring_segments = 6
	_anillo.mesh = toro
	_anillo.position.y = 0.05
	_anillo.material_override = _material(AZUL)
	add_child(_anillo)

	_icono = Sprite3D.new()
	_icono.texture = ICONO_CAMARA
	_icono.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_icono.pixel_size = 1.1 / ICONO_CAMARA.get_width()
	_icono.modulate = Color(0.75, 0.9, 1.0)
	add_child(_icono)

	var titulo := Label3D.new()
	titulo.text = "Reto de foto"
	titulo.font_size = 40
	titulo.outline_size = 10
	titulo.pixel_size = 0.008
	titulo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	titulo.position.y = 2.6
	add_child(titulo)

	var area := Area3D.new()
	var forma := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 1.3
	forma.shape = esfera
	forma.position.y = 1.2
	area.add_child(forma)
	add_child(area)

	scale = Vector3.ONE * 0.01   # (escala 0 no le gusta a la física)
	create_tween().tween_property(self, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_tiempo += delta
	_icono.position.y = 1.6 + sin(_tiempo * 2.0) * 0.15
	var pulso := 1.0 + sin(_tiempo * 3.5) * 0.08
	_anillo.scale = Vector3(pulso, 1, pulso)


func al_tocar(_quien: Node3D) -> void:
	get_parent().reto_foto_tocado(self)


func desaparecer() -> void:
	for area in find_children("*", "Area3D", true, false):
		(area as Area3D).collision_layer = 0   # mientras se va ya no se puede tocar
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ONE * 0.01, 0.3)
	tween.tween_callback(queue_free)


func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat
