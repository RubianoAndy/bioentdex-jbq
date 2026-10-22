extends Control
## Guía Macrofotográfica: consejos generales + un consejo por cada especie descubierta.

const CONSEJOS_GENERALES := [
	"Acércate despacio y sin movimientos bruscos.",
	"Enfoca siempre los ojos del animal.",
	"Prefiere la luz suave de la mañana o del final de la tarde.",
	"Apoya los codos o usa un trípode para que la foto no salga movida.",
	"Respeta el hábitat: no muevas plantas ni toques a los animales.",
]

@onready var lista: VBoxContainer = $Margen/VBox/Scroll/Lista


func _ready() -> void:
	$Margen/VBox/Encabezado/BtnVolver.pressed.connect(_on_volver_pressed)

	var generales := ""
	for consejo in CONSEJOS_GENERALES:
		generales += "• %s\n" % consejo
	_agregar_ficha("Consejos generales", generales.strip_edges())

	var por_descubrir := 0
	for especie in RegistroEspecies.especies:
		if RegistroEspecies.esta_descubierta(especie.id):
			_agregar_ficha(especie.nombre_comun, especie.consejo_macro, especie.obtener_imagen())
		else:
			por_descubrir += 1
	if por_descubrir > 0:
		_agregar_ficha("Faltan %d especies" % por_descubrir,
			"Descúbrelas en la expedición para desbloquear sus consejos.")


func _agregar_ficha(titulo: String, texto: String, imagen: Texture2D = null) -> void:
	var margen := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 16)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 16)
	margen.add_child(fila)

	if imagen:
		var miniatura := TextureRect.new()
		miniatura.texture = imagen
		miniatura.custom_minimum_size = Vector2(120, 120)
		miniatura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		miniatura.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fila.add_child(miniatura)

	var columna := VBoxContainer.new()
	columna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(columna)

	var etiqueta_titulo := Label.new()
	etiqueta_titulo.text = titulo
	etiqueta_titulo.add_theme_font_size_override("font_size", 28)
	columna.add_child(etiqueta_titulo)

	var etiqueta_texto := Label.new()
	etiqueta_texto.text = texto
	etiqueta_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta_texto.add_theme_font_size_override("font_size", 22)
	columna.add_child(etiqueta_texto)

	var panel := PanelContainer.new()
	panel.add_child(margen)
	lista.add_child(panel)


func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://MenuPrincipal.tscn")
