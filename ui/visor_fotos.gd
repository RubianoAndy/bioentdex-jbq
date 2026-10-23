class_name VisorFotos
extends Control
## Visor de fotos a pantalla completa:
##   - Doble toque, pellizcar o la rueda del mouse: zoom. Con zoom, arrastrar mueve la foto.
##   - Sin zoom, deslizar a los lados (o las flechas): foto anterior / siguiente.

const ZOOM_MAXIMO := 5.0

var _fotos: Array = []
var _indice := 0
var _titulo := ""
var _zoom := 1.0
var _desplazamiento := Vector2.ZERO
var _toques := {}
var _arrastre_x := 0.0
var _ultimo_toque := 0.0

var _area: Control
var _foto: TextureRect
var _contador: Label


static func abrir(padre: Node, fotos: Array, desde: int, titulo := "") -> VisorFotos:
	var visor := VisorFotos.new()
	visor._fotos = fotos
	visor._indice = desde
	visor._titulo = titulo
	padre.add_child(visor)
	return visor


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var fondo := ColorRect.new()
	fondo.color = Color.BLACK
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	_area = Control.new()
	_area.clip_contents = true
	_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_area.gui_input.connect(_on_area_input)
	_foto = TextureRect.new()
	_foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_foto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_area.add_child(_foto)
	add_child(_area)
	_area.resized.connect(_acomodar)

	# Barra de arriba: título, contador y cerrar
	var barra := HBoxContainer.new()
	barra.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	barra.offset_left = 16
	barra.offset_right = -16
	barra.offset_top = 16
	barra.offset_bottom = 80
	barra.add_theme_constant_override("separation", 12)
	add_child(barra)
	var titulo := Label.new()
	titulo.text = _titulo
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 24)
	barra.add_child(titulo)
	_contador = Label.new()
	_contador.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_contador.add_theme_font_size_override("font_size", 22)
	_contador.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	barra.add_child(_contador)
	var cerrar := Button.new()
	cerrar.text = "×"
	cerrar.custom_minimum_size = Vector2(64, 64)
	cerrar.add_theme_font_size_override("font_size", 40)
	cerrar.pressed.connect(queue_free)
	barra.add_child(cerrar)

	var ayuda := Label.new()
	ayuda.text = "Doble toque o pellizca para ampliar · desliza para ver otra foto"
	ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ayuda.add_theme_font_size_override("font_size", 18)
	ayuda.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	ayuda.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	ayuda.offset_top = -60
	ayuda.offset_bottom = -24
	ayuda.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ayuda)

	_mostrar(_indice)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.18)


func _mostrar(nuevo: int) -> void:
	_indice = wrapi(nuevo, 0, _fotos.size())
	_foto.texture = _fotos[_indice]
	_contador.text = "%d / %d" % [_indice + 1, _fotos.size()]
	_zoom = 1.0
	_desplazamiento = Vector2.ZERO
	_acomodar()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right"):
		_mostrar(_indice + 1)
	elif event.is_action_pressed("ui_left"):
		_mostrar(_indice - 1)
	elif event.is_action_pressed("ui_cancel"):
		queue_free()


## Ajusta la foto para que quepa completa en pantalla, con el zoom y el desplazamiento actuales.
func _acomodar() -> void:
	if _foto.texture == null or _area.size.x <= 0.0:
		return
	var tamano_foto := Vector2(_foto.texture.get_width(), _foto.texture.get_height())
	var escala := minf(_area.size.x / tamano_foto.x, _area.size.y / tamano_foto.y)
	_foto.size = tamano_foto * escala * _zoom
	var libre := (_foto.size - _area.size) / 2.0
	_desplazamiento.x = clampf(_desplazamiento.x, -maxf(libre.x, 0.0), maxf(libre.x, 0.0))
	_desplazamiento.y = clampf(_desplazamiento.y, -maxf(libre.y, 0.0), maxf(libre.y, 0.0))
	_foto.position = (_area.size - _foto.size) / 2.0 + _desplazamiento


func _hacer_zoom(nuevo: float, centro: Vector2) -> void:
	nuevo = clampf(nuevo, 1.0, ZOOM_MAXIMO)
	var desde_centro := centro - _area.size / 2.0 - _desplazamiento
	_desplazamiento -= desde_centro * (nuevo / _zoom - 1.0)
	_zoom = nuevo
	_acomodar()


func _on_area_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_toques[event.index] = event.position
			if _toques.size() == 1:
				_arrastre_x = 0.0
				var ahora := Time.get_ticks_msec() / 1000.0
				if ahora - _ultimo_toque < 0.3:   # doble toque
					_hacer_zoom(2.5 if _zoom < 1.5 else 1.0, event.position)
				_ultimo_toque = ahora
		else:
			_toques.erase(event.index)
			if _toques.is_empty() and _zoom <= 1.01 and absf(_arrastre_x) > 90.0:
				_mostrar(_indice + (1 if _arrastre_x < 0.0 else -1))
	elif event is InputEventScreenDrag:
		if _toques.size() >= 2 and _toques.has(event.index):
			# Pellizcar: el zoom sigue la separación de los dedos
			var otro: Vector2 = _toques[_toques.keys().filter(func(k) -> bool: return k != event.index)[0]]
			var antes: float = otro.distance_to(_toques[event.index])
			_toques[event.index] = event.position
			if antes > 10.0:
				_hacer_zoom(_zoom * otro.distance_to(event.position) / antes, (otro + event.position) / 2.0)
		else:
			_toques[event.index] = event.position
			if _zoom > 1.01:
				_desplazamiento += event.relative
				_acomodar()
			else:
				_arrastre_x += event.relative.x
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_hacer_zoom(_zoom * 1.2, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_hacer_zoom(_zoom / 1.2, event.position)
	elif event is InputEventMagnifyGesture:
		_hacer_zoom(_zoom * event.factor, event.position)
