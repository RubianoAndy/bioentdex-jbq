extends Control
## Pantalla del mapa: conecta el mundo 3D con la interfaz (zonas, fauna, captura y fichas).

const CAPTURA := preload("res://captura/CapturaAR.tscn")
const ESCENA_MAPA := "res://MapaExpedicion.tscn"

enum ModoVisualizacion { ESTUDIO_NORMAL, REALIDAD_AUMENTADA, REALIDAD_VIRTUAL }

@onready var mundo: Node3D = $SubViewportContainer/SubViewport/Mundo3D
@onready var fauna: Node3D = $SubViewportContainer/SubViewport/Mundo3D/Fauna
@onready var retos: Node3D = $SubViewportContainer/SubViewport/Mundo3D/Retos
@onready var panel_zona: PanelContainer = $PanelZona
@onready var nombre_zona: Label = $PanelZona/Margen/HBox/NombreZona
@onready var entorno_mundo: WorldEnvironment = $SubViewportContainer/SubViewport/Mundo3D/WorldEnvironment
@onready var modelo_organismo: Node3D = $SubViewportContainer/SubViewport/Mundo3D/Fauna
@onready var entorno_virtual_rv: Node3D = $SubViewportContainer/SubViewport/Mundo3D
@onready var ui_boton_modo: Button = $BotonesDerecha/BtnModo
@onready var subviewport: SubViewport = $SubViewportContainer/SubViewport
@onready var nubes: Control = $Nubes

var _burbuja_colibri: BurbujaColibri
var _camara_mapa := CamaraDispositivo.new()
var _entorno_virtual_base: Environment
var _visibilidad_entorno: Dictionary = {}
var modo_actual: ModoVisualizacion = ModoVisualizacion.ESTUDIO_NORMAL
var xr_interface: XRInterface
var _camara_ra_activa := false
var _xr_activo := false
var _xr_inicializado := false
var _cambiando_modo := false


func _ready() -> void:
	AudioManager.conectar_botones(self)
	_entorno_virtual_base = entorno_mundo.environment.duplicate()
	add_child(_camara_mapa)
	_cambiando_modo = true
	await verificar_permisos_movil()
	_cambiando_modo = false
	AudioManager.reproducir_paisaje_humedal()
	mundo.zona_cercana_cambio.connect(_on_zona_cercana_cambio)
	ui_boton_modo.pressed.connect(_ciclar_modo_visualizacion)
	$PanelZona/Margen/HBox/BtnEntrar.pressed.connect(_on_entrar_pressed)
	$BotonesDerecha/BtnBioentdex.pressed.connect(_ir_a.bind("res://Bioentdex.tscn"))
	$BotonesDerecha/BtnExplorador.pressed.connect(_ir_a.bind("res://Personalizar.tscn"))
	$BotonesDerecha/BtnTarjeta.pressed.connect(_ir_a.bind("res://comunidad/tarjeta_hallazgo.tscn"))
	fauna.insecto_seleccionado.connect(_on_insecto_seleccionado)
	fauna.npc_seleccionado.connect(_on_npc_seleccionado)
	mundo.colibri.tocado.connect(_on_colibri_tocado)
	mundo.colibri.vuelo_cercano.connect(_on_colibri_vuelo_cercano)
	mundo.colibri.se_despide.connect(func() -> void: _burbuja_colibri.cerrar())
	retos.reto_foto_seleccionado.connect(_on_reto_foto_seleccionado)
	retos.batalla_seleccionada.connect(_on_batalla_seleccionada)

	var insignia := InsigniaJugador.new()
	insignia.position = Vector2(16, 86)
	insignia.tocada.connect(_ir_a.bind("res://Tienda.tscn"))
	add_child(insignia)
	move_child(insignia, $PanelZona.get_index())

	# Burbuja del colibrí: sigue al colibrí cuando llega junto al explorador
	_burbuja_colibri = BurbujaColibri.new()
	_burbuja_colibri.configurar(mundo.colibri, mundo.camara, $SubViewportContainer)
	add_child(_burbuja_colibri)
	move_child(_burbuja_colibri, $PanelZona.get_index())

	# Capa para los avisos: queda debajo de la cámara y de las fichas (que se agregan después)
	var avisos := Control.new()
	avisos.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	avisos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(avisos)
	fauna.aviso.connect(func(texto: String) -> void: Aviso.mostrar(avisos, texto))
	retos.aviso.connect(func(texto: String) -> void: Aviso.mostrar(avisos, texto))

	if RegistroEspecies.cantidad_descubiertas() == 0:
		await get_tree().create_timer(1.5).timeout
		Aviso.mostrar(avisos, "Los insectos con anillo dorado se pueden fotografiar. Los demás animales solo se observan.")


func _exit_tree() -> void:
	_camara_mapa.detener()
	_detener_openxr()
	AudioManager.detener_paisaje_humedal()


func verificar_permisos_movil() -> void:
	if not OS.has_feature("android"):
		return
	for permiso in ["android.permission.CAMERA", "android.permission.ACCESS_FINE_LOCATION"]:
		await _camara_mapa.solicitar_permiso_android(permiso)


func _ciclar_modo_visualizacion() -> void:
	if _cambiando_modo:
		return
	FeedbackTactil.interaccion()
	match modo_actual:
		ModoVisualizacion.ESTUDIO_NORMAL:
			await cambiar_a_ra()
		ModoVisualizacion.REALIDAD_AUMENTADA:
			cambiar_a_rv()
		ModoVisualizacion.REALIDAD_VIRTUAL:
			cambiar_a_normal()


func cambiar_a_ra() -> void:
	if _cambiando_modo:
		return
	_cambiando_modo = true
	modo_actual = ModoVisualizacion.REALIDAD_AUMENTADA
	print("Cambiando a Realidad Aumentada (Cámara activa)")
	_detener_openxr()
	ui_boton_modo.text = "Iniciando..."
	_camara_ra_activa = await _camara_mapa.iniciar()
	if _camara_ra_activa:
		entorno_mundo.environment = _entorno_virtual_original()
		entorno_mundo.environment.background_mode = Environment.BG_CAMERA_FEED
		entorno_mundo.environment.background_camera_feed_id = _camara_mapa.identificador_feed()
		_ocultar_entorno_virtual()
	elif OS.has_feature("android"):
		entorno_mundo.environment = _entorno_virtual_original()
		Aviso.mostrar(self, "No se pudo acceder a la cámara. Puedes continuar en modo simulación.")
	else:
		entorno_mundo.environment = _entorno_virtual_original()
	_restaurar_modelo_organismo()
	ui_boton_modo.text = "RA"
	ui_boton_modo.tooltip_text = "RA con cámara. Toca para cambiar a RV." if _camara_ra_activa else "RA simulada: cámara no disponible. Toca para cambiar a RV."
	_cambiando_modo = false


func cambiar_a_rv() -> void:
	_cambiando_modo = true
	modo_actual = ModoVisualizacion.REALIDAD_VIRTUAL
	print("Cambiando a Realidad Virtual / Inmersiva (Entorno digital activo)")
	_camara_mapa.detener()
	_camara_ra_activa = false
	entorno_mundo.environment = _entorno_virtual_original()
	_restaurar_entorno_virtual()
	entorno_virtual_rv.show()
	_restaurar_modelo_organismo()
	_xr_activo = _inicializar_openxr()
	ui_boton_modo.text = "RV"
	ui_boton_modo.tooltip_text = "RV con OpenXR. Toca para volver a Normal." if _xr_activo else "RV simulada: OpenXR no disponible. Toca para volver a Normal."
	_cambiando_modo = false


func cambiar_a_normal() -> void:
	_cambiando_modo = true
	modo_actual = ModoVisualizacion.ESTUDIO_NORMAL
	print("Cambiando a Vista de Estudio / Normal (Fondo limpio)")
	_camara_mapa.detener()
	_camara_ra_activa = false
	_detener_openxr()
	entorno_mundo.environment = _entorno_virtual_original()
	_restaurar_entorno_virtual()
	entorno_virtual_rv.show()
	_restaurar_modelo_organismo()
	ui_boton_modo.text = "Normal"
	ui_boton_modo.tooltip_text = "Estudio normal. Toca para pasar a RA."
	_cambiando_modo = false


func _entorno_virtual_original() -> Environment:
	return _entorno_virtual_base.duplicate()


func _ocultar_entorno_virtual() -> void:
	# Mundo3D también es el padre de Fauna; se ocultan sus capas para mantener visible el organismo.
	_visibilidad_entorno.clear()
	for nodo in entorno_virtual_rv.get_children():
		if nodo in [modelo_organismo, mundo.camara, entorno_mundo] or nodo.name == "Luz":
			continue
		if nodo is Node3D:
			_visibilidad_entorno[nodo] = nodo.visible
			nodo.hide()
	nubes.hide()


func _restaurar_entorno_virtual() -> void:
	for nodo in _visibilidad_entorno:
		if is_instance_valid(nodo):
			nodo.visible = _visibilidad_entorno[nodo]
	_visibilidad_entorno.clear()
	nubes.show()


func _restaurar_modelo_organismo() -> void:
	modelo_organismo.show()


func _inicializar_openxr() -> bool:
	if OS.get_name() == "Windows":
		return false
	xr_interface = XRServer.find_interface("OpenXR")
	if not xr_interface:
		return false
	if not _xr_inicializado:
		_xr_inicializado = xr_interface.initialize()
	if not _xr_inicializado:
		return false
	subviewport.use_xr = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	xr_interface.start()
	return true


func _detener_openxr() -> void:
	if _xr_activo and xr_interface:
		xr_interface.stop()
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	subviewport.use_xr = false
	_xr_activo = false


func _suspender_ra_para_captura() -> bool:
	if modo_actual != ModoVisualizacion.REALIDAD_AUMENTADA or not _camara_ra_activa:
		return false
	_camara_mapa.detener()
	_camara_ra_activa = false
	entorno_mundo.environment = _entorno_virtual_original()
	_restaurar_entorno_virtual()
	return true


func _reanudar_ra_despues_captura(reanudar: bool) -> void:
	if reanudar:
		await cambiar_a_ra()


func _on_zona_cercana_cambio(zona: Zona) -> void:
	# Al llegar a una zona aparece el panel de abajo con el botón "Entrar"
	panel_zona.visible = zona != null
	if zona:
		nombre_zona.text = zona.nombre


func _on_colibri_vuelo_cercano() -> void:
	var zona_id: String = mundo.zona_actual.id if mundo.zona_actual else ""
	_burbuja_colibri.mostrar(DialogosColibri.siguiente(zona_id))


## En el PC: Enter entra a la zona cercana (las flechas mueven al explorador, ver mundo_3d.gd).
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and panel_zona.visible and mundo.zona_actual:
		get_viewport().set_input_as_handled()
		_on_entrar_pressed()


func _on_entrar_pressed() -> void:
	FeedbackTactil.interaccion()
	Expedicion.entrar_a_zona(mundo.zona_actual, mundo.explorador.position)


## Abre la cámara para capturar el insecto. El mapa se pausa mientras tanto.
func _on_insecto_seleccionado(insecto: Node3D) -> void:
	FeedbackTactil.interaccion()
	var reanudar_ra := _suspender_ra_para_captura()
	var captura := CAPTURA.instantiate()
	captura.especie = insecto.especie
	captura.zona_id = mundo.zona_actual.id if mundo.zona_actual else ""
	captura.tipo_fondo = _fondo_en(insecto)
	_pausar_mapa(true)
	captura.terminada.connect(func(_capturado: bool) -> void:
		_pausar_mapa(false)
		_reanudar_ra_despues_captura(reanudar_ra)
		fauna.quitar_insecto(insecto))   # capturado o escapado, ya no está en el mapa
	add_child(captura)


## Reto de foto del mapa: abre la cámara y guarda la foto en la base de datos.
func _on_reto_foto_seleccionado(marcador: Node3D) -> void:
	FeedbackTactil.interaccion()
	var reanudar_ra := _suspender_ra_para_captura()
	_pausar_mapa(true)
	var reto := RetoFoto.mostrar(self, marcador.mision, marcador.zona_id, _fondo_en(marcador))
	reto.terminado.connect(func(cumplido: bool) -> void:
		_pausar_mapa(false)
		_reanudar_ra_despues_captura(reanudar_ra)
		if cumplido:
			retos.quitar(marcador))


## Emboscada: batalla de preguntas contra el depredador del globo.
func _on_batalla_seleccionada(globo: Node3D) -> void:
	FeedbackTactil.interaccion()
	_pausar_mapa(true)
	var zona_id: String = mundo.zona_actual.id if mundo.zona_actual else ""
	var batalla := Batalla.mostrar(self, globo.depredador, globo.premio, zona_id, _fondo_en(globo))
	batalla.terminada.connect(func(peleo: bool) -> void:
		_pausar_mapa(false)
		if peleo:
			retos.quitar(globo))   # gane o pierda, el globo se va


## Mientras hay una pantalla encima (cámara, batalla) el mapa 3D no se procesa ni recibe toques.
func _pausar_mapa(pausar: bool) -> void:
	mundo.cancelar_toque()   # que no queden toques viejos de antes de abrir la pantalla
	$SubViewportContainer.process_mode = Node.PROCESS_MODE_DISABLED if pausar else Node.PROCESS_MODE_INHERIT


## Los animales NPC no se capturan: se observan y se ve su ficha.
func _on_npc_seleccionado(especie: Especie) -> void:
	FeedbackTactil.interaccion()
	mundo.cancelar_toque()
	var primera := RegistroEspecies.registrar_observacion(especie)
	var ficha := FichaEspecie.new()
	ficha.mostrar(self, especie, "¡Nuevo avistamiento!" if primera else "Avistamiento")


func _on_colibri_tocado(especie: Especie) -> void:
	AudioManager.reproducir_sfx("aviso_colibri")
	_on_npc_seleccionado(especie)


func _fondo_en(nodo: Node3D) -> String:
	return _fondo_para(mundo.terreno.clase_en(Vector2(nodo.position.x, nodo.position.z)))


func _fondo_para(clase: int) -> String:
	if clase in [PaletaMapa.AGUA, PaletaMapa.FLOTANTES, PaletaMapa.JUNCAL, PaletaMapa.PUENTE]:
		return "agua"
	if clase == PaletaMapa.BOSQUE:
		return "bosque"
	return "pradera"


func _ir_a(escena: String) -> void:
	FeedbackTactil.interaccion()
	Expedicion.posicion_explorador = mundo.explorador.position
	Perfil.volver_a = ESCENA_MAPA
	get_tree().change_scene_to_file(escena)


func _on_btn_regresar_pressed() -> void:
	FeedbackTactil.interaccion()
	Expedicion.posicion_explorador = mundo.explorador.position
	get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
