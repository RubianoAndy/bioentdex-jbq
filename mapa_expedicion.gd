extends Control

@onready var mundo: Node3D = $SubViewportContainer/SubViewport/Mundo3D
@onready var panel_zona: PanelContainer = $PanelZona
@onready var nombre_zona: Label = $PanelZona/Margen/HBox/NombreZona


func _ready() -> void:
	mundo.zona_cercana_cambio.connect(_on_zona_cercana_cambio)
	$PanelZona/Margen/HBox/BtnEntrar.pressed.connect(_on_entrar_pressed)
	RegistroEspecies.especie_descubierta.connect(_on_especie_descubierta)


func _on_zona_cercana_cambio(zona: Zona) -> void:
	# Al llegar a una zona aparece el panel de abajo con el botón "Entrar"
	panel_zona.visible = zona != null
	if zona:
		nombre_zona.text = zona.nombre


func _on_entrar_pressed() -> void:
	Expedicion.entrar_a_zona(mundo.zona_actual, mundo.explorador.position)


func _on_especie_descubierta(especie: Especie) -> void:
	Aviso.mostrar(self, "¡Nueva especie: %s!" % especie.nombre_comun)


func _on_btn_regresar_pressed() -> void:
	# Vuelve instantáneamente al menú principal
	get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
