extends Node3D
## Insecto que se puede capturar con la cámara. Aparece cerca del explorador por un rato y se va.
## Se distingue de los animales NPC por el anillo dorado, los destellos y el ícono de cámara.

const ICONO_CAMARA := preload("res://ui/icono_camara.svg")
const DORADO := Color(1.0, 0.82, 0.25)
const ESCALA := 1.6   # en el mapa se ven más grandes que a escala real, como en Pokémon GO

var especie: Especie
var vida := 90.0          # segundos que se queda en el mapa
var _tiempo := randf() * TAU
var _sprite: Sprite3D
var _anillo: MeshInstance3D
var _icono: Sprite3D


func configurar(nueva_especie: Especie, pos: Vector2, duracion: float) -> void:
	especie = nueva_especie
	vida = duracion
	position = Vector3(pos.x, 0, pos.y)


func _ready() -> void:
	var halo := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = 0.75
	disco.bottom_radius = 0.75
	disco.height = 0.01
	halo.mesh = disco
	halo.position.y = 0.03
	halo.material_override = _material(Color(DORADO, 0.25))
	add_child(halo)

	_anillo = MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 0.62
	toro.outer_radius = 0.78
	toro.rings = 24
	toro.ring_segments = 6
	_anillo.mesh = toro
	_anillo.position.y = 0.05
	_anillo.material_override = _material(DORADO)
	add_child(_anillo)

	_sprite = Sprite3D.new()
	_sprite.texture = especie.imagen_mapa()
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	if _sprite.texture:
		_sprite.pixel_size = especie.tamano_en_mapa * ESCALA / maxf(_sprite.texture.get_width(), _sprite.texture.get_height())
	add_child(_sprite)

	_icono = Sprite3D.new()
	_icono.texture = ICONO_CAMARA
	_icono.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_icono.pixel_size = 0.45 / ICONO_CAMARA.get_width()
	_icono.position = Vector3(0.45, 1.75, 0)
	add_child(_icono)

	var destellos := CPUParticles3D.new()
	destellos.amount = 10
	destellos.lifetime = 1.4
	destellos.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	destellos.emission_sphere_radius = 0.7
	destellos.gravity = Vector3(0, 0.5, 0)
	destellos.initial_velocity_min = 0.1
	destellos.initial_velocity_max = 0.3
	var punto := SphereMesh.new()
	punto.radius = 0.04
	punto.height = 0.08
	punto.radial_segments = 4
	punto.rings = 2
	punto.material = _material(Color(1, 0.95, 0.6))
	destellos.mesh = punto
	destellos.position.y = 0.6
	add_child(destellos)

	var area := Area3D.new()
	var forma := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 1.2
	forma.shape = esfera
	forma.position.y = 0.9
	area.add_child(forma)
	add_child(area)

	# Aparece con un "pop"
	scale = Vector3.ONE * 0.01   # (escala 0 no le gusta a la física)
	create_tween().tween_property(self, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_tiempo += delta
	# Revoloteo: sube, baja y se mece
	_sprite.position = Vector3(sin(_tiempo * 1.7) * 0.15, 0.95 + sin(_tiempo * 3.1) * 0.15, 0)
	var pulso := 1.0 + sin(_tiempo * 4.0) * 0.08
	_anillo.scale = Vector3(pulso, 1, pulso)
	_icono.position.y = 1.75 + sin(_tiempo * 2.0) * 0.06


func al_tocar(_quien: Node3D) -> void:
	get_parent().insecto_tocado(self)


func desaparecer() -> void:
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
