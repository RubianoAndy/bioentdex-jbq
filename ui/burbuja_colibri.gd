class_name BurbujaColibri
extends Control
## Burbuja de diálogo del colibrí en el mapa: aparece pegada al colibrí mientras está junto al
## explorador, con un dato curioso y una barrita que muestra cuánto tiempo le queda.
## Tocar la burbuja la cierra y el colibrí sigue su vuelo.

const ANCHO := 360.0
const MARGEN := 16.0
const ALTO_COLA := 18.0
const SEPARACION := 34.0      # píxeles entre la punta de la cola y el colibrí
const LIMITE_SUPERIOR := 150.0  # no tapar los botones de arriba
const FONDO := Color(1, 1, 0.98)
const BORDE := Color(0.2, 0.55, 0.42)
const VERDE := Color(0.16, 0.48, 0.36)
const TEXTO := Color(0.17, 0.22, 0.2)

var colibri: Node3D
var camara: Camera3D
var contenedor: SubViewportContainer
var vista: SubViewport

var _panel: PanelContainer
var _titulo: Label
var _texto: Label
var _barra: ColorRect
var _fondo_barra: ColorRect
var _abierta := false
var _abajo := false              # true si la burbuja va debajo del colibrí
var _punta := Vector2.ZERO
var _tween: Tween


func configurar(nuevo_colibri: Node3D, nueva_camara: Camera3D, nuevo_contenedor: SubViewportContainer) -> void:
	colibri = nuevo_colibri
	camara = nueva_camara
	contenedor = nuevo_contenedor
	vista = camara.get_viewport() as SubViewport


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	_panel = PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = FONDO
	estilo.border_color = BORDE
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(18)
	estilo.content_margin_left = 14
	estilo.content_margin_right = 14
	estilo.content_margin_top = 9
	estilo.content_margin_bottom = 9
	estilo.shadow_color = Color(0, 0, 0, 0.22)
	estilo.shadow_size = 6
	estilo.shadow_offset = Vector2(0, 3)
	_panel.add_theme_stylebox_override("panel", estilo)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.gui_input.connect(_on_panel_gui_input)
	add_child(_panel)

	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 4)
	columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(columna)

	_titulo = Label.new()
	_titulo.add_theme_font_size_override("font_size", 14)
	_titulo.add_theme_color_override("font_color", VERDE)
	columna.add_child(_titulo)

	_texto = Label.new()
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.add_theme_font_size_override("font_size", 16)
	_texto.add_theme_constant_override("line_spacing", -2)
	# Ancho fijo para que el texto sepa dónde partir las líneas y la burbuja mida lo justo
	_texto.custom_minimum_size = Vector2(ANCHO - 28.0, 0)
	_texto.add_theme_color_override("font_color", TEXTO)
	columna.add_child(_texto)

	# Barrita del tiempo restante
	_fondo_barra = ColorRect.new()
	_fondo_barra.color = Color(BORDE, 0.15)
	_fondo_barra.custom_minimum_size = Vector2(0, 3)
	_fondo_barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.add_child(_fondo_barra)
	_barra = ColorRect.new()
	_barra.color = Color(BORDE, 0.75)
	_barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fondo_barra.add_child(_barra)


## Abre la burbuja con un diálogo de DialogosColibri.
func mostrar(dialogo: Dictionary) -> void:
	if dialogo.is_empty():
		return
	_titulo.text = "Colibrí · " + DialogosColibri.nombre_categoria(str(dialogo.get("categoria", "")))
	_texto.text = dialogo.get("texto", "")
	_abierta = true
	visible = true
	_panel.reset_size()
	_ubicar()
	_animar(true)


func cerrar() -> void:
	if not _abierta:
		return
	_abierta = false
	_animar(false)


func _animar(entrar: bool) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel()
	if entrar:
		modulate.a = 0.0
		_panel.scale = Vector2(0.7, 0.7)
		_tween.tween_property(self, "modulate:a", 1.0, 0.25)
		_tween.tween_property(_panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_tween.tween_property(self, "modulate:a", 0.0, 0.35)
		_tween.tween_property(_panel, "scale", Vector2(0.85, 0.85), 0.35)
		_tween.chain().tween_callback(func() -> void: visible = _abierta)


func _process(_delta: float) -> void:
	if not visible or not is_instance_valid(colibri):
		return
	_ubicar()
	if _abierta and colibri.has_method("tiempo_restante_visita"):
		var fraccion := clampf(colibri.tiempo_restante_visita() / maxf(0.01, colibri.duracion_visita), 0.0, 1.0)
		_barra.size = Vector2(_fondo_barra.size.x * fraccion, _fondo_barra.size.y)
	queue_redraw()


## Pone la burbuja encima del colibrí (o debajo si no cabe) sin salirse de la pantalla.
func _ubicar() -> void:
	if camara == null or camara.is_position_behind(colibri.global_position):
		return
	var en_vista := camara.unproject_position(colibri.global_position)
	var escala := contenedor.size / Vector2(vista.size)
	var p := contenedor.global_position - global_position + en_vista * escala
	_panel.size = _panel.get_combined_minimum_size()   # nunca más grande que su contenido
	var tam := _panel.size
	_abajo = p.y - SEPARACION - ALTO_COLA - tam.y < LIMITE_SUPERIOR
	var x := clampf(p.x - tam.x / 2.0, MARGEN, size.x - tam.x - MARGEN)
	var y := p.y + SEPARACION + ALTO_COLA if _abajo else p.y - SEPARACION - ALTO_COLA - tam.y
	_panel.position = Vector2(x, y)
	_panel.pivot_offset = Vector2(clampf(p.x - x, 0, tam.x), 0.0 if _abajo else tam.y)
	_punta = Vector2(p.x, p.y + SEPARACION * 0.6 if _abajo else p.y - SEPARACION * 0.6)


## La colita de la burbuja, que apunta al colibrí.
func _draw() -> void:
	if not visible:
		return
	var rect := _panel.get_transform() * Rect2(Vector2.ZERO, _panel.size)
	var base_x := clampf(_punta.x, rect.position.x + 40.0, rect.end.x - 40.0)
	var base_y := rect.position.y + 2.0 if _abajo else rect.end.y - 2.0
	var ancho := 12.0
	var cola := PackedVector2Array([Vector2(base_x - ancho, base_y), Vector2(base_x + ancho, base_y), _punta])
	draw_colored_polygon(cola, FONDO)
	draw_polyline(PackedVector2Array([Vector2(base_x - ancho, base_y), _punta, Vector2(base_x + ancho, base_y)]), BORDE, 2.0, true)


func _on_panel_gui_input(event: InputEvent) -> void:
	var toque: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)
	if toque and _abierta:
		accept_event()
		if colibri.has_method("despedirse"):
			colibri.despedirse()
		else:
			cerrar()
