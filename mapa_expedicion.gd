extends Control

func _ready() -> void:
	# Dejamos _ready limpio porque la señal ya está conectada por el editor
	pass

func _on_btn_regresar_pressed() -> void:
	# Vuelve instantáneamente al menú principal
	get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
