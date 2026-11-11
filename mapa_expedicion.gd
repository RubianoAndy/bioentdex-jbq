extends Control
## Pantalla del mapa: conecta el mundo 3D con la interfaz (zonas, fauna, captura y fichas).

const CAPTURA := preload("res://captura/CapturaAR.tscn")
const ESCENA_MAPA := "res://MapaExpedicion.tscn"
const FICHA_ESPECIE_SCRIPT := preload("res://ui/ficha_especie.gd")

@onready var mundo: Node3D = $SubViewportContainer/SubViewport/Mundo3D
@onready var fauna: Node3D = $SubViewportContainer/SubViewport/Mundo3D/Fauna
@onready var retos: Node3D = $SubViewportContainer/SubViewport/Mundo3D/Retos
@onready var panel_zona: PanelContainer = $PanelZona
@onready var nombre_zona: Label = $PanelZona/Margen/HBox/NombreZona


func _ready() -> void:
	AudioManager.conectar_botones(self)
	AudioManager.reproducir_paisaje_humedal()
	mundo.zona_cercana_cambio.connect(_on_zona_cercana_cambio)
	$PanelZona/Margen/HBox/BtnEntrar.pressed.connect(_on_entrar_pressed)
	$BotonesDerecha/BtnBioentdex.pressed.connect(_ir_a.bind("res://Bioentdex.tscn"))
	$BotonesDerecha/BtnExplorador.pressed.connect(_ir_a.bind("res://Personalizar.tscn"))
	fauna.insecto_seleccionado.connect(_on_insecto_seleccionado)
	fauna.npc_seleccionado.connect(_on_npc_seleccionado)
	mundo.colibri.tocado.connect(_on_colibri_tocado)
	retos.reto_foto_seleccionado.connect(_on_reto_foto_seleccionado)
	retos.batalla_seleccionada.connect(_on_batalla_seleccionada)
	$CompaneroColibri.establecer_contexto("")

	var insignia := InsigniaJugador.new()
	insignia.position = Vector2(16, 86)
	insignia.tocada.connect(_ir_a.bind("res://Tienda.tscn"))
	add_child(insignia)
	move_child(insignia, $PanelZona.get_index())

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
	AudioManager.detener_paisaje_humedal()


func _on_zona_cercana_cambio(zona: Zona) -> void:
	# Al llegar a una zona aparece el panel de abajo con el botón "Entrar"
	panel_zona.visible = zona != null
	$CompaneroColibri.establecer_contexto(zona.id if zona else "")
	if zona:
		nombre_zona.text = zona.nombre


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
	var captura := CAPTURA.instantiate()
	captura.especie = insecto.especie
	captura.zona_id = mundo.zona_actual.id if mundo.zona_actual else ""
	captura.tipo_fondo = _fondo_en(insecto)
	_pausar_mapa(true)
	captura.terminada.connect(func(_capturado: bool) -> void:
		_pausar_mapa(false)
		fauna.quitar_insecto(insecto))   # capturado o escapado, ya no está en el mapa
	add_child(captura)


## Reto de foto del mapa: abre la cámara y guarda la foto en la base de datos.
func _on_reto_foto_seleccionado(marcador: Node3D) -> void:
	FeedbackTactil.interaccion()
	_pausar_mapa(true)
	var reto := RetoFoto.mostrar(self, marcador.mision, marcador.zona_id, _fondo_en(marcador))
	reto.terminado.connect(func(cumplido: bool) -> void:
		_pausar_mapa(false)
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
	FICHA_ESPECIE_SCRIPT.mostrar(self, especie, "¡Nuevo avistamiento!" if primera else "Avistamiento")


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
