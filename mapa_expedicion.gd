extends Control
## Pantalla del mapa: conecta el mundo 3D con la interfaz (zonas, fauna, captura y fichas).

const CAPTURA := preload("res://captura/CapturaAR.tscn")
const ESCENA_MAPA := "res://MapaExpedicion.tscn"

@onready var mundo: Node3D = $SubViewportContainer/SubViewport/Mundo3D
@onready var fauna: Node3D = $SubViewportContainer/SubViewport/Mundo3D/Fauna
@onready var panel_zona: PanelContainer = $PanelZona
@onready var nombre_zona: Label = $PanelZona/Margen/HBox/NombreZona


func _ready() -> void:
	mundo.zona_cercana_cambio.connect(_on_zona_cercana_cambio)
	$PanelZona/Margen/HBox/BtnEntrar.pressed.connect(_on_entrar_pressed)
	$BotonesDerecha/BtnBioentdex.pressed.connect(_ir_a.bind("res://Bioentdex.tscn"))
	$BotonesDerecha/BtnExplorador.pressed.connect(_ir_a.bind("res://Personalizar.tscn"))
	fauna.insecto_seleccionado.connect(_on_insecto_seleccionado)
	fauna.npc_seleccionado.connect(_on_npc_seleccionado)
	mundo.colibri.tocado.connect(_on_npc_seleccionado)

	# Capa para los avisos: queda debajo de la cámara y de las fichas (que se agregan después)
	var avisos := Control.new()
	avisos.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	avisos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(avisos)
	fauna.aviso.connect(func(texto: String) -> void: Aviso.mostrar(avisos, texto))

	if RegistroEspecies.cantidad_descubiertas() == 0:
		await get_tree().create_timer(1.5).timeout
		Aviso.mostrar(avisos, "Los insectos con anillo dorado se pueden fotografiar. Los demás animales solo se observan.")


func _on_zona_cercana_cambio(zona: Zona) -> void:
	# Al llegar a una zona aparece el panel de abajo con el botón "Entrar"
	panel_zona.visible = zona != null
	if zona:
		nombre_zona.text = zona.nombre


func _on_entrar_pressed() -> void:
	Expedicion.entrar_a_zona(mundo.zona_actual, mundo.explorador.position)


## Abre la cámara para capturar el insecto. El mapa se pausa mientras tanto.
func _on_insecto_seleccionado(insecto: Node3D) -> void:
	var captura := CAPTURA.instantiate()
	captura.especie = insecto.especie
	captura.zona_id = mundo.zona_actual.id if mundo.zona_actual else ""
	captura.tipo_fondo = _fondo_para(mundo.terreno.clase_en(Vector2(insecto.position.x, insecto.position.z)))
	$SubViewportContainer.process_mode = Node.PROCESS_MODE_DISABLED
	captura.terminada.connect(func(_capturado: bool) -> void:
		$SubViewportContainer.process_mode = Node.PROCESS_MODE_INHERIT
		fauna.quitar_insecto(insecto))   # capturado o escapado, ya no está en el mapa
	add_child(captura)


## Los animales NPC no se capturan: se observan y se ve su ficha.
func _on_npc_seleccionado(especie: Especie) -> void:
	var primera := RegistroEspecies.registrar_observacion(especie)
	FichaEspecie.mostrar(self, especie, "¡Nuevo avistamiento!" if primera else "Avistamiento")


func _fondo_para(clase: int) -> String:
	if clase in [PaletaMapa.AGUA, PaletaMapa.FLOTANTES, PaletaMapa.JUNCAL, PaletaMapa.PUENTE]:
		return "agua"
	if clase == PaletaMapa.BOSQUE:
		return "bosque"
	return "pradera"


func _ir_a(escena: String) -> void:
	Expedicion.posicion_explorador = mundo.explorador.position
	Perfil.volver_a = ESCENA_MAPA
	get_tree().change_scene_to_file(escena)


func _on_btn_regresar_pressed() -> void:
	Expedicion.posicion_explorador = mundo.explorador.position
	get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
