extends Control

func _ready() -> void:
	# Conectamos el primer botón del menú para que abra el mapa del humedal
	$VBoxContainer/Button.pressed.connect(_on_iniciar_expedicion_pressed)
	$VBoxContainer/Button2.pressed.connect(_on_guia_macro_pressed)
	$VBoxContainer/Button3.pressed.connect(_on_bioentdex_pressed)

func _on_iniciar_expedicion_pressed() -> void:
	# Salto hacia la escena del mapa de expedición
	get_tree().change_scene_to_file("res://MapaExpedicion.tscn")

func _on_guia_macro_pressed() -> void:
	get_tree().change_scene_to_file("res://GuiaMacro.tscn")

func _on_bioentdex_pressed() -> void:
	get_tree().change_scene_to_file("res://Bioentdex.tscn")
