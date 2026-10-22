extends Control
## Interior de una zona: aparecen las especies que viven ahí. Toca los "?" para descubrirlas.

const TAMANO_ESPECIE := Vector2(180, 210)

@onready var escenario: Control = $Margen/VBox/Escenario

var zona: Zona


func _ready() -> void:
	# Si se abre la escena sola desde el editor (F6), se usa la primera zona
	zona = Expedicion.zona_actual if Expedicion.zona_actual else Expedicion.zonas[0]
	$Fondo.color = zona.color.darkened(0.65)
	$Margen/VBox/Encabezado/Titulo.text = zona.nombre
	$Margen/VBox/Descripcion.text = zona.descripcion
	$Margen/VBox/Encabezado/BtnVolver.pressed.connect(Expedicion.volver_al_mapa)
	RegistroEspecies.especie_descubierta.connect(_on_especie_descubierta)

	await get_tree().process_frame   # esperar a que el escenario tenga su tamaño final
	_colocar_especies()


func _colocar_especies() -> void:
	# Cada especie va en una franja horizontal distinta, en una posición al azar
	var franja := escenario.size.y / maxi(1, zona.especies.size())
	for i in zona.especies.size():
		var especie := zona.especies[i]
		var boton := Button.new()
		boton.custom_minimum_size = TAMANO_ESPECIE
		boton.size = TAMANO_ESPECIE
		boton.pivot_offset = TAMANO_ESPECIE / 2.0
		boton.expand_icon = true
		boton.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		boton.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		boton.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		boton.position = Vector2(
			randf() * maxf(0.0, escenario.size.x - TAMANO_ESPECIE.x),
			franja * i + randf() * maxf(0.0, franja - TAMANO_ESPECIE.y))
		escenario.add_child(boton)
		boton.pressed.connect(_on_especie_pressed.bind(boton, especie))
		_actualizar_boton(boton, especie)


func _actualizar_boton(boton: Button, especie: Especie) -> void:
	if RegistroEspecies.esta_descubierta(especie.id):
		boton.icon = especie.imagen
		boton.text = especie.nombre_comun
		boton.remove_theme_font_size_override("font_size")
		boton.scale = Vector2.ONE
		if boton.has_meta("latido"):
			boton.get_meta("latido").kill()
			boton.remove_meta("latido")
	else:
		boton.icon = null
		boton.text = "?"
		boton.add_theme_font_size_override("font_size", 72)
		var latido := boton.create_tween().set_loops()
		latido.tween_property(boton, "scale", Vector2(1.08, 1.08), 0.6)
		latido.tween_property(boton, "scale", Vector2.ONE, 0.6)
		boton.set_meta("latido", latido)


func _on_especie_pressed(boton: Button, especie: Especie) -> void:
	if RegistroEspecies.descubrir(especie.id):
		_actualizar_boton(boton, especie)
	else:
		Aviso.mostrar(self, "%s ya está en tu Bioentdex" % especie.nombre_comun)


func _on_especie_descubierta(especie: Especie) -> void:
	Aviso.mostrar(self, "¡Nueva especie: %s!" % especie.nombre_comun)
