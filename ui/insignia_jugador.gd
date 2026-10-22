class_name InsigniaJugador
extends PanelContainer
## Insignia del jugador: nivel, barra de experiencia y semillas (y el néctar si está activo).
## Al tocarla se abre la tienda.

signal tocada

const DORADO := Color(1, 0.84, 0.3)

var _nivel: Label
var _barra: ProgressBar
var _xp: Label
var _semillas: Label
var _nectar: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.06, 0.14, 0.1, 0.88)
	estilo.set_corner_radius_all(34)
	estilo.border_color = Color(DORADO, 0.7)
	estilo.set_border_width_all(2)
	estilo.content_margin_left = 6
	estilo.content_margin_right = 18
	estilo.content_margin_top = 6
	estilo.content_margin_bottom = 6
	add_theme_stylebox_override("panel", estilo)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fila)

	var circulo := PanelContainer.new()
	circulo.custom_minimum_size = Vector2(58, 58)
	var redondo := StyleBoxFlat.new()
	redondo.bg_color = DORADO
	redondo.set_corner_radius_all(29)
	redondo.set_border_width_all(3)
	redondo.border_color = Color.WHITE
	circulo.add_theme_stylebox_override("panel", redondo)
	_nivel = _etiqueta(26, Color(0.3, 0.2, 0.02))
	_nivel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nivel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	circulo.add_child(_nivel)
	fila.add_child(circulo)

	var columna := VBoxContainer.new()
	columna.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_theme_constant_override("separation", 3)
	columna.custom_minimum_size = Vector2(150, 0)
	_xp = _etiqueta(16, Color(1, 1, 1, 0.85))
	columna.add_child(_xp)
	_barra = ProgressBar.new()
	_barra.show_percentage = false
	_barra.custom_minimum_size = Vector2(150, 10)
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(1, 1, 1, 0.18)
	fondo.set_corner_radius_all(5)
	var relleno := StyleBoxFlat.new()
	relleno.bg_color = Color(0.4, 0.9, 0.6)
	relleno.set_corner_radius_all(5)
	_barra.add_theme_stylebox_override("background", fondo)
	_barra.add_theme_stylebox_override("fill", relleno)
	columna.add_child(_barra)
	_nectar = _etiqueta(14, DORADO)
	columna.add_child(_nectar)
	fila.add_child(columna)

	var moneda := TextureRect.new()
	moneda.texture = load("res://ui/semilla.svg")
	moneda.custom_minimum_size = Vector2(38, 38)
	moneda.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	moneda.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	moneda.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(moneda)
	_semillas = _etiqueta(26, DORADO)
	_semillas.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fila.add_child(_semillas)

	Recompensas.cambio.connect(_actualizar)
	_actualizar()


func _process(_delta: float) -> void:
	var segundos := Recompensas.segundos_nectar()
	_nectar.visible = segundos > 0
	if segundos > 0:
		_nectar.text = "Néctar %d:%02d" % [segundos / 60, segundos % 60]


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tocada.emit()


func _actualizar() -> void:
	var progreso := Recompensas.progreso_nivel()
	_nivel.text = str(Recompensas.nivel())
	_xp.text = "Nivel %d · %d/%d XP" % [Recompensas.nivel(), progreso.x, progreso.y]
	_barra.max_value = progreso.y
	_barra.value = progreso.x
	_semillas.text = str(Recompensas.semillas())


func _etiqueta(tamano: int, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return etiqueta
