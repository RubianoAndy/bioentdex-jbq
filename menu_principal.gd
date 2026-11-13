extends Control
## Pantalla de inicio: el mapa ilustrado de fondo con un acercamiento lento, nubes y los botones.

const ESCENA_MENU := "res://MenuPrincipal.tscn"
const TOQUES_ADMIN := 5
const VENTANA_TOQUES_ADMIN_MS := 2500

var _toques_admin := 0
var _ultimo_toque_admin := 0

func _ready() -> void:
	var etiqueta_titulo: Label = $Titulo/Nombre
	etiqueta_titulo.gui_input.connect(_on_titulo_gui_input)
	$Botones/BtnExpedicion.pressed.connect(_ir_a.bind("res://MapaExpedicion.tscn"))
	$Botones/BtnBioentdex.pressed.connect(_ir_a.bind("res://Bioentdex.tscn"))
	$Botones/BtnGuia.pressed.connect(_ir_a.bind("res://GuiaMacro.tscn"))
	$Botones/BtnPersonalizar.pressed.connect(_ir_a.bind("res://Personalizar.tscn"))
	$Saludo.text = "Hola, %s" % Perfil.nombre
	$Botones/BtnTienda.pressed.connect(_ir_a.bind("res://Tienda.tscn"))
	var insignia := InsigniaJugador.new()
	insignia.position = Vector2(16, 16)
	insignia.tocada.connect(_ir_a.bind("res://Tienda.tscn"))
	add_child(insignia)

	# Botón para quitar el sonido, arriba a la derecha
	var sonido := BotonSonido.new()
	sonido.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	sonido.offset_left = -72
	sonido.offset_right = -16
	sonido.offset_top = 16
	sonido.offset_bottom = 72
	add_child(sonido)

	# El fondo se acerca y se aleja muy despacio
	var fondo: TextureRect = $Fondo
	var vaiven := create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	vaiven.tween_property(fondo, "scale", Vector2(1.08, 1.08), 18.0)
	vaiven.tween_property(fondo, "scale", Vector2.ONE, 18.0)

	# Entrada del título y los botones
	var titulo: Control = $Titulo
	titulo.modulate.a = 0.0
	titulo.position.y -= 40
	var entrada := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entrada.tween_property(titulo, "modulate:a", 1.0, 0.6)
	entrada.tween_property(titulo, "position:y", titulo.position.y + 40, 0.7)
	var botones: Control = $Botones
	botones.modulate.a = 0.0
	entrada.tween_property(botones, "modulate:a", 1.0, 0.6).set_delay(0.3)


func _on_titulo_gui_input(event: InputEvent) -> void:
	var pulsacion := false
	if event is InputEventMouseButton:
		var clic := event as InputEventMouseButton
		pulsacion = clic.pressed and clic.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		pulsacion = (event as InputEventScreenTouch).pressed
	if not pulsacion:
		return

	var ahora := Time.get_ticks_msec()
	if ahora - _ultimo_toque_admin > VENTANA_TOQUES_ADMIN_MS:
		_toques_admin = 0
	_ultimo_toque_admin = ahora
	_toques_admin += 1
	if _toques_admin < TOQUES_ADMIN:
		return

	_toques_admin = 0
	get_viewport().set_input_as_handled()
	_ir_a("res://ui/analitica_docente.tscn")


func _ir_a(escena: String) -> void:
	Perfil.volver_a = ESCENA_MENU
	get_tree().change_scene_to_file(escena)
