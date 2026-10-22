extends Node3D
## Mapa del humedal estilo Google Maps: el explorador camina por el mapa y la cámara lo sigue.
## Toca el suelo para caminar hasta ahí, toca una zona para ir a ella, arrastra para mover el mapa.

signal zona_cercana_cambio(zona: Zona)   # null cuando el explorador sale de la zona

const MARCADOR_ZONA := preload("res://marcador_zona.gd")

## Máscara de colores que define el humedal (ver mapa/paleta_mapa.gd). Se puede repintar en Paint.
@export var mascara: Texture2D
@export var velocidad_teclado := 5.0       # con las flechas, para probar en el computador
@export var sensibilidad_arrastre := 0.035  # unidades del mapa por cada píxel arrastrado
@export var distancia_toque := 12.0        # píxeles: si el dedo se mueve menos, es un toque

@onready var suelo: MeshInstance3D = $Suelo
@onready var camara: Camera3D = $Camera3D
@onready var explorador: Node3D = $Explorador
@onready var colibri: Node3D = $Colibri

var zona_actual: Zona = null
var terreno: Terreno
var _offset_camara: Vector3
var _inicio_toque := Vector2.ZERO
var _es_arrastre := false
var _toque_pendiente = null   # Vector2 o null; se procesa en _physics_process


func _ready() -> void:
	var tamano: Vector2 = suelo.mesh.size
	var ruido := NoiseTexture2D.new()
	ruido.seamless = true
	ruido.noise = FastNoiseLite.new()
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://mapa/suelo_humedal.gdshader")
	mat.set_shader_parameter("mascara", mascara)
	mat.set_shader_parameter("ruido", ruido)
	mat.set_shader_parameter("tamano_mapa", tamano)
	suelo.material_override = mat

	# El terreno sabe por dónde se puede caminar; la vegetación y las zonas le agregan obstáculos
	terreno = Terreno.new(mascara, tamano)
	$Vegetacion.generar(terreno, Expedicion.zonas)
	DecoracionZonas.decorar(self, Expedicion.zonas, terreno)
	explorador.terreno = terreno
	$Fauna.configurar(terreno, explorador, Expedicion.zonas)

	colibri.limites = Rect2(-tamano / 2.0, tamano).grow(-1.0)
	colibri.explorador = explorador

	for zona in Expedicion.zonas:
		var marcador := MARCADOR_ZONA.new()
		marcador.configurar(zona)
		add_child(marcador)

	# La cámara conserva la distancia que tiene en el editor respecto al explorador
	_offset_camara = camara.position - explorador.position
	explorador.position = Expedicion.posicion_explorador
	camara.position = explorador.position + _offset_camara


func _process(delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir != Vector2.ZERO:
		explorador.mover(Vector3(dir.x, 0, dir.y) * velocidad_teclado * delta)

	camara.position = camara.position.lerp(explorador.position + _offset_camara, minf(1.0, 8.0 * delta))
	_revisar_zona_cercana()


func _input(event: InputEvent) -> void:
	# En PC el mouse llega como toque gracias a "Emular táctil desde mouse" (project.godot).
	if event is InputEventScreenTouch and event.index == 0:
		if event.pressed:
			_inicio_toque = event.position
			_es_arrastre = false
		elif not _es_arrastre:
			_toque_pendiente = event.position
	elif event is InputEventScreenDrag and event.index == 0:
		if not _es_arrastre and event.position.distance_to(_inicio_toque) > distancia_toque:
			_es_arrastre = true
		if _es_arrastre:
			# El mapa sigue al dedo: el explorador avanza en sentido contrario al arrastre
			explorador.mover(Vector3(-event.relative.x, 0, -event.relative.y) * sensibilidad_arrastre)


func _physics_process(_delta: float) -> void:
	# Los rayos de física se lanzan aquí, que es donde el espacio físico es seguro de consultar
	if _toque_pendiente != null:
		_tocar(_toque_pendiente)
		_toque_pendiente = null


func _tocar(posicion_pantalla: Vector2) -> void:
	var origen := camara.project_ray_origin(posicion_pantalla)
	var direccion := camara.project_ray_normal(posicion_pantalla)

	# ¿Tocó algo con área (colibrí, marcador de zona)?
	var consulta := PhysicsRayQueryParameters3D.create(origen, origen + direccion * 100.0)
	consulta.collide_with_areas = true
	consulta.collide_with_bodies = false
	var choque := get_world_3d().direct_space_state.intersect_ray(consulta)
	if choque and choque.collider.get_parent().has_method("al_tocar"):
		choque.collider.get_parent().al_tocar(explorador)
		return

	# Si no, caminar hasta el punto tocado del suelo
	var punto = Plane(Vector3.UP, 0.0).intersects_ray(origen, direccion)
	if punto != null:
		explorador.ir_a(punto)


func _revisar_zona_cercana() -> void:
	var cercana: Zona = null
	var pos := Vector2(explorador.position.x, explorador.position.z)
	for zona in Expedicion.zonas:
		if pos.distance_to(zona.posicion) <= zona.radio:
			cercana = zona
			break
	if cercana != zona_actual:
		zona_actual = cercana
		zona_cercana_cambio.emit(zona_actual)
