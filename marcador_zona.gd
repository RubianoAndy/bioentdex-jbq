extends Node3D
## Punto de una zona en el mapa: círculo de color en el suelo, pin flotante y nombre.
## Al tocarlo, el explorador camina hasta la zona.

var zona: Zona
var _pin: Node3D
var _tiempo := randf() * TAU


func configurar(nueva_zona: Zona) -> void:
	zona = nueva_zona
	position = Vector3(zona.posicion.x, 0, zona.posicion.y)


func _ready() -> void:
	var circulo := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = zona.radio
	disco.bottom_radius = zona.radio
	disco.height = 0.02
	disco.radial_segments = 48
	circulo.mesh = disco
	circulo.position.y = 0.02
	circulo.material_override = _material(Color(zona.color, 0.3))
	add_child(circulo)

	_pin = Node3D.new()
	add_child(_pin)
	var cabeza := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.35
	esfera.height = 0.7
	cabeza.mesh = esfera
	cabeza.material_override = _material(zona.color)
	_pin.add_child(cabeza)
	var punta := MeshInstance3D.new()
	var cono := CylinderMesh.new()
	cono.top_radius = 0.3
	cono.bottom_radius = 0.0
	cono.height = 0.7
	punta.mesh = cono
	punta.position.y = -0.45
	punta.material_override = _material(zona.color)
	_pin.add_child(punta)

	var nombre := Label3D.new()
	nombre.text = zona.nombre
	nombre.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	nombre.font_size = 48
	nombre.outline_size = 12
	nombre.pixel_size = 0.008
	nombre.position.y = 2.6
	add_child(nombre)

	# Área para detectar el toque (ver mundo_3d.gd)
	var area := Area3D.new()
	var forma := CollisionShape3D.new()
	var cilindro := CylinderShape3D.new()
	cilindro.radius = zona.radio
	cilindro.height = 3.0
	forma.shape = cilindro
	forma.position.y = 1.5
	area.add_child(forma)
	add_child(area)


func _process(delta: float) -> void:
	_tiempo += delta
	_pin.position.y = 1.6 + sin(_tiempo * 2.0) * 0.15
	_pin.rotate_y(delta)


func al_tocar(explorador: Node3D) -> void:
	explorador.ir_a(position)


func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat
