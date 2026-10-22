extends Control
## Personalizar el explorador: nombre, piel, ropa, sombrero y mochila (se guarda en el Perfil).

@onready var explorador: Node3D = $Margen/VBox/Vista/SubViewport/Explorador
@onready var opciones: VBoxContainer = $Margen/VBox/Scroll/Opciones


func _ready() -> void:
	$Margen/VBox/Encabezado/BtnVolver.pressed.connect(_volver)
	$Margen/VBox/BtnGuardar.pressed.connect(func() -> void:
		Perfil.guardar()
		_volver())
	_construir()


func _process(delta: float) -> void:
	explorador.rotate_y(delta * 0.6)


func _construir() -> void:
	for hijo in opciones.get_children():
		hijo.queue_free()

	opciones.add_child(_titulo("Nombre"))
	var nombre := LineEdit.new()
	nombre.text = Perfil.nombre
	nombre.max_length = 20
	nombre.custom_minimum_size = Vector2(0, 60)
	nombre.text_changed.connect(func(texto: String) -> void: Perfil.nombre = texto)
	opciones.add_child(nombre)

	_fila_colores("Piel", Perfil.PIELES, "piel")
	_fila_colores("Camisa", Perfil.CAMISAS, "camisa")
	_fila_colores("Pantalón", Perfil.PANTALONES, "pantalon")

	opciones.add_child(_titulo("Sombrero"))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	for i in Perfil.SOMBREROS.size():
		var boton := Button.new()
		boton.text = Perfil.SOMBREROS[i]
		boton.custom_minimum_size = Vector2(0, 56)
		boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		boton.toggle_mode = true
		boton.button_pressed = Perfil.sombrero == i
		boton.pressed.connect(_elegir.bind("sombrero", i))
		fila.add_child(boton)
	opciones.add_child(fila)

	_fila_colores("Color del sombrero", Perfil.COLORES_SOMBRERO, "color_sombrero")
	_fila_colores("Mochila", Perfil.MOCHILAS, "mochila")


func _fila_colores(titulo: String, colores: Array, propiedad: String) -> void:
	opciones.add_child(_titulo(titulo))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	for i in colores.size():
		var muestra := Button.new()
		muestra.custom_minimum_size = Vector2(68, 68)
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = colores[i]
		estilo.set_corner_radius_all(34)
		var elegido: bool = Perfil.get(propiedad) == i
		estilo.set_border_width_all(6 if elegido else 2)
		estilo.border_color = Color(1, 0.84, 0.3) if elegido else Color(0, 0, 0, 0.4)
		for estado in ["normal", "hover", "pressed", "focus"]:
			muestra.add_theme_stylebox_override(estado, estilo)
		muestra.pressed.connect(_elegir.bind(propiedad, i))
		fila.add_child(muestra)
	opciones.add_child(fila)


func _elegir(propiedad: String, valor: int) -> void:
	Perfil.set(propiedad, valor)
	explorador.aplicar_perfil()
	_construir.call_deferred()


func _titulo(texto: String) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.add_theme_font_size_override("font_size", 24)
	etiqueta.add_theme_color_override("font_color", Color(1, 0.84, 0.3))
	return etiqueta


func _volver() -> void:
	get_tree().change_scene_to_file(Perfil.volver_a)
