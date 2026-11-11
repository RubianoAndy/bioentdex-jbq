extends Node3D
## Mapa del humedal estilo Google Maps: el explorador camina por el mapa y la cámara lo sigue.
## Toca el suelo para caminar hasta ahí, toca una zona para ir a ella, desliza el dedo para caminar.

signal zona_cercana_cambio(zona: Zona)   # null cuando el explorador sale de la zona

const MARCADOR_ZONA := preload("res://marcador_zona.gd")

## Máscara de colores que define el humedal (ver mapa/paleta_mapa.gd). Se puede repintar en Paint.
@export var mascara: Texture2D
@export var velocidad_teclado := 5.0       # con las flechas, para probar en el computador
@export var sensibilidad_arrastre := 0.018  # unidades del mapa por cada píxel arrastrado
@export var sensibilidad_camara := 8.0     # rapidez con que la cámara sigue al explorador
@export var velocidad_arrastre := 9.0       # tope al arrastrar, para que el explorador no salga disparado
@export var distancia_toque := 24.0        # píxeles: si el dedo se mueve menos, es un toque

@onready var suelo: MeshInstance3D = $Suelo
@onready var camara: Camera3D = $Camera3D
@onready var explorador: Node3D = $Explorador
@onready var colibri: Node3D = $Colibri

var zona_actual: Zona = null
var terreno: Terreno
var _offset_camara: Vector3
var _inicio_toque := Vector2.ZERO
var _es_arrastre := false
var _dedo_abajo := false      # solo cuenta el arrastre si el mapa vio empezar el toque
var _arrastre_pendiente := Vector3.ZERO   # lo arrastrado que el explorador aún no ha caminado
var _toque_pendiente = null   # Vector2 o null; se procesa en _physics_process


## Distancia en el plano horizontal del mapa (Vector2 representa X y Z).
static func distancia_xz(origen: Vector2, destino: Vector2) -> float:
	return origen.distance_to(destino)


func _ready() -> void:
	var tamano: Vector2 = suelo.mesh.size
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://mapa/suelo_humedal.gdshader")
	mat.set_shader_parameter("mascara", mascara)
	mat.set_shader_parameter("ruido", Expedicion.ruido_suelo)   # generado al abrir la app
	mat.set_shader_parameter("tamano_mapa", tamano)
	suelo.material_override = mat

	# Alrededores: la máscara termina en ciudad, así que fuera del mapa sigue un andén gris claro.
	# Sin esto, al caminar cerca del borde se veía el vacío.
	var alrededores := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = tamano * 4.0
	alrededores.mesh = plano
	alrededores.position.y = -0.05
	var mat_alrededores := StandardMaterial3D.new()
	mat_alrededores.albedo_color = Color(0.62, 0.6, 0.56)   # mismo color del andén en el shader del suelo
	mat_alrededores.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	alrededores.material_override = mat_alrededores
	alrededores.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(alrededores)

	# El terreno sabe por dónde se puede caminar; la vegetación y las zonas le agregan obstáculos
	if mascara == Expedicion.MASCARA and tamano == Expedicion.TAMANO_MAPA:
		var datos := Expedicion.datos_mapa()   # ya precalculado al abrir la app
		terreno = datos[0]
		$Vegetacion.construir(datos[1])
	else:
		terreno = Terreno.new(mascara.get_image(), tamano)
		$Vegetacion.construir($Vegetacion.calcular(terreno, Expedicion.zonas))
	# El shader del suelo lee el tipo de suelo ya clasificado en vez de calcularlo por píxel
	var clases := Image.create_from_data(terreno.ancho, terreno.alto, false, Image.FORMAT_R8, terreno.clases)
	mat.set_shader_parameter("clases", ImageTexture.create_from_image(clases))
	mat.set_shader_parameter("usar_clases", true)

	# En el celular el 3D se dibuja al 75 % de la resolución (casi no se nota y es bastante más fluido)
	if OS.has_feature("mobile"):
		get_viewport().scaling_3d_scale = 0.75

	DecoracionZonas.decorar(self, Expedicion.zonas, terreno)
	explorador.terreno = terreno
	$Fauna.configurar(terreno, explorador, Expedicion.zonas)
	$Retos.configurar(terreno, explorador, Expedicion.zonas)

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
	# Teclado solo en el PC: en el celular un control o sensor reconocido como joystick lo movería solo
	if not OS.has_feature("mobile"):
		var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if dir != Vector2.ZERO:
			explorador.mover(Vector3(dir.x, 0, dir.y) * velocidad_teclado * delta)

	# El arrastre se camina a velocidad limitada, no de golpe con cada evento del dedo
	if _arrastre_pendiente != Vector3.ZERO:
		var paso := _arrastre_pendiente.limit_length(velocidad_arrastre * delta)
		explorador.mover(paso)
		_arrastre_pendiente -= paso
		if _arrastre_pendiente.length() < 0.001:
			_arrastre_pendiente = Vector3.ZERO

	camara.position = camara.position.lerp(explorador.position + _offset_camara, minf(1.0, sensibilidad_camara * delta))
	_revisar_zona_cercana()


func _input(event: InputEvent) -> void:
	# En PC el mouse llega como toque gracias a "Emular táctil desde mouse" (project.godot).
	if event is InputEventScreenTouch and event.index == 0:
		if event.pressed:
			_inicio_toque = event.position
			_es_arrastre = false
			_dedo_abajo = true
		else:
			if _dedo_abajo and not _es_arrastre:
				_toque_pendiente = event.position
			_dedo_abajo = false
	elif event is InputEventScreenDrag and event.index == 0 and _dedo_abajo:
		if not _es_arrastre and event.position.distance_to(_inicio_toque) > distancia_toque:
			_es_arrastre = true
			explorador.detener()
		if _es_arrastre:
			# El explorador camina hacia donde se desliza el dedo (derecha = derecha, abajo = abajo).
			# Se acumula poco (máx. 2 unidades) para que al soltar no siga caminando.
			_arrastre_pendiente += Vector3(event.relative.x, 0, event.relative.y) * sensibilidad_arrastre
			_arrastre_pendiente = _arrastre_pendiente.limit_length(2.0)


func _notification(what: int) -> void:
	# Si la app pierde el foco (permiso de cámara, notificación, cambiar de app) o el mapa se pausa
	# para abrir la cámara, el "soltar" del dedo puede no llegar nunca: se olvida el toque para que
	# el explorador no quede caminando.
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED,
			NOTIFICATION_DISABLED, NOTIFICATION_ENABLED]:
		cancelar_toque()


## Olvida el toque o arrastre en curso y detiene al explorador (al abrir la cámara, una ficha...).
func cancelar_toque() -> void:
	_dedo_abajo = false
	_es_arrastre = false
	_arrastre_pendiente = Vector3.ZERO
	_toque_pendiente = null
	if explorador:
		explorador.detener()


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
		if distancia_xz(pos, zona.posicion) <= zona.radio:
			cercana = zona
			break
	if cercana != zona_actual:
		zona_actual = cercana
		zona_cercana_cambio.emit(zona_actual)
