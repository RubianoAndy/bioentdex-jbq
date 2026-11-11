extends Control
## Pantalla de inicio: el mapa ilustrado de fondo con un acercamiento lento, nubes y los botones.

const ESCENA_MENU := "res://MenuPrincipal.tscn"


func _ready() -> void:
	$Botones/BtnExpedicion.pressed.connect(_ir_a.bind("res://MapaExpedicion.tscn"))
	$Botones/BtnBioentdex.pressed.connect(_ir_a.bind("res://Bioentdex.tscn"))
	$Botones/BtnGuia.pressed.connect(_ir_a.bind("res://GuiaMacro.tscn"))
	$Botones/BtnPersonalizar.pressed.connect(_ir_a.bind("res://Personalizar.tscn"))
	$Saludo.text = "Hola, %s" % Perfil.nombre
	$Botones/BtnTienda.pressed.connect(_ir_a.bind("res://Tienda.tscn"))
	$Botones/BtnAnalitica.pressed.connect(_ir_a.bind("res://ui/analitica_docente.tscn"))
	var insignia := InsigniaJugador.new()
	insignia.position = Vector2(16, 16)
	insignia.tocada.connect(_ir_a.bind("res://Tienda.tscn"))
	add_child(insignia)

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


func _ir_a(escena: String) -> void:
	Perfil.volver_a = ESCENA_MENU
	get_tree().change_scene_to_file(escena)
