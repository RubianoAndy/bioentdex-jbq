class_name VistaModelo3D
extends SubViewportContainer
## Muestra el modelo 3D de una especie (en cualquier fase de su ciclo de vida) girando despacio,
## con fondo transparente. Aparece con un fundido cuando el primer cuadro ya está dibujado (antes
## de eso la textura de un SubViewport se ve negra). Si "silueta" es true se ve como sombra oscura
## (fases que aún no se desbloquean).

var especie: Especie
var etapa := ""
var silueta := false
var girar := true

var _vista: SubViewport
var _pivote: Node3D
var _tiempo := randf() * 10.0


func configurar(nueva_especie: Especie, nueva_etapa := "", tamano := 160.0, en_silueta := false) -> VistaModelo3D:
	especie = nueva_especie
	etapa = nueva_etapa
	silueta = en_silueta
	custom_minimum_size = Vector2(tamano, tamano)
	return self


func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vista = SubViewport.new()
	_vista.transparent_bg = true
	_vista.own_world_3d = true
	_vista.msaa_3d = Viewport.MSAA_2X
	add_child(_vista)
	var ambiente := WorldEnvironment.new()
	ambiente.environment = Environment.new()
	ambiente.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.environment.ambient_light_color = Color(0.75, 0.75, 0.8)
	ambiente.environment.ambient_light_energy = 0.8
	_vista.add_child(ambiente)
	var luz := DirectionalLight3D.new()
	luz.rotation = Vector3(-0.9, 0.5, 0)
	_vista.add_child(luz)
	var camara := Camera3D.new()
	camara.fov = 30.0
	camara.position = Vector3(0, 0.9, 2.6)
	_vista.add_child(camara)
	camara.look_at(Vector3(0, 0.38, 0))
	_pivote = Node3D.new()
	_vista.add_child(_pivote)
	cambiar_etapa(etapa)
	if silueta:
		modulate = Color(0, 0, 0, 0.55)
	_aparecer()


## Cambia el modelo por el de otra fase (lo usa la celebración de evolución).
func cambiar_etapa(nueva_etapa: String) -> void:
	etapa = nueva_etapa
	for hijo in _pivote.get_children():
		hijo.queue_free()
	var modelo := ModelosEspecies.crear(especie, 1.0, etapa)
	if modelo:
		_pivote.add_child(modelo)


func _process(delta: float) -> void:
	if girar and _pivote:
		_tiempo += delta
		_pivote.rotation.y = sin(_tiempo * 0.7) * 0.9 + 0.4


func _aparecer() -> void:
	var final := modulate.a
	modulate.a = 0.0
	for i in 2:
		await RenderingServer.frame_post_draw
	if is_inside_tree():
		create_tween().tween_property(self, "modulate:a", final, 0.25)
