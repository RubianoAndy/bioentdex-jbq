class_name VisorGuia
extends Control
## Visor de la "Guía macrofotográfica sobre insectos del Humedal Jaboque" dentro de la app.
## Las páginas del PDF (guia/Guia.pdf) están convertidas a imágenes en guia/paginas/ para que la guía
## se lea sin descargarla ni abrir otra aplicación.
##   - Deslizar el dedo a los lados (o los botones / flechas del teclado): cambiar de página.
##   - Doble toque, pellizcar o la rueda del mouse: zoom. Con zoom, arrastrar mueve la página.
## Se abre como pantalla (desde el menú) o como ventana encima de otra (desde la ficha de una especie).

const CARPETA := "res://guia/paginas/pagina_%03d.jpg"
const TOTAL_PAGINAS := 121
const ZOOM_MAXIMO := 4.0

## Órdenes de insectos de la guía y la página donde empieza cada uno
const PAGINAS_ORDEN := {
	"Diptera": 37, "Hemiptera": 52, "Psocodea": 58, "Odonata": 62, "Hymenoptera": 71,
	"Lepidoptera": 83, "Coleoptera": 93, "Dermaptera": 100, "Neuroptera": 105, "Zygentoma": 110,
}

## Índice: [texto, página, nivel de sangría]
const INDICE := [
	["Portada", 1, 0], ["Créditos", 3, 0], ["Contenido", 5, 0], ["Índice de órdenes y familias", 6, 0],
	["Cap. 1 · Bienvenida", 7, 0], ["Cap. 2 · El humedal", 10, 0], ["Cap. 3 · El mundo de los insectos", 17, 0],
	["Cap. 4 · Características, historia e importancia", 22, 0], ["Cap. 5 · Órdenes y familias del humedal", 34, 0],
	["Orden Diptera · moscas y zancudos", 37, 1], ["Tipulidae", 39, 2], ["Calliphoridae", 41, 2], ["Syrphidae", 43, 2],
	["Culicidae", 46, 2], ["Tachinidae", 49, 2],
	["Orden Hemiptera · chinches", 52, 1], ["Miridae", 55, 2],
	["Orden Psocodea · piojos de la corteza", 58, 1], ["Psocidae", 59, 2],
	["Orden Odonata · libélulas", 62, 1], ["Suborden Anisoptera", 65, 2], ["Suborden Zygoptera", 68, 2],
	["Orden Hymenoptera · hormigas, abejas y avispas", 71, 1], ["Formicidae", 74, 2], ["Apidae", 78, 2], ["Vespidae", 81, 2],
	["Orden Lepidoptera · mariposas y polillas", 83, 1], ["Pieridae", 86, 2], ["Nymphalidae", 88, 2], ["Geometridae", 91, 2],
	["Orden Coleoptera · escarabajos", 93, 1], ["Chrysomelidae", 96, 2], ["Coccinellidae", 98, 2],
	["Orden Dermaptera · tijeretas", 100, 1], ["Forficulidae", 103, 2],
	["Orden Neuroptera · crisopas", 105, 1], ["Chrysopidae", 108, 2],
	["Orden Zygentoma · pececillos de plata", 110, 1], ["Lepismatidae", 113, 2],
	["Recomendaciones para tomar macrofotografías", 115, 0], ["Referencias", 116, 0],
]

var pagina := 1
var como_ventana := false     # true: "Volver" solo cierra el visor

var _zoom := 1.0
var _desplazamiento := Vector2.ZERO
var _toques := {}             # índice del dedo -> posición
var _arrastre_x := 0.0
var _ultimo_toque := 0.0

@onready var area: Control = $VBox/Area
@onready var hoja: TextureRect = $VBox/Area/Pagina
@onready var numero: Label = $VBox/Barra/Numero


## Abre la guía encima de la pantalla actual, en la página indicada.
static func abrir(padre: Node, en_pagina: int) -> VisorGuia:
	var visor: VisorGuia = load("res://GuiaMacro.tscn").instantiate()
	visor.pagina = en_pagina
	visor.como_ventana = true
	padre.add_child(visor)
	return visor


func _ready() -> void:
	$VBox/Encabezado/BtnVolver.pressed.connect(_volver)
	$VBox/Encabezado/BtnIndice.pressed.connect(_mostrar_indice)
	$VBox/Barra/BtnAnterior.pressed.connect(func() -> void: ir_a(pagina - 1))
	$VBox/Barra/BtnSiguiente.pressed.connect(func() -> void: ir_a(pagina + 1))
	area.gui_input.connect(_on_area_input)
	area.resized.connect(_acomodar)
	ir_a(pagina)


func ir_a(nueva: int) -> void:
	pagina = clampi(nueva, 1, TOTAL_PAGINAS)
	hoja.texture = load(CARPETA % pagina)
	numero.text = "Página %d de %d" % [pagina, TOTAL_PAGINAS]
	$VBox/Barra/BtnAnterior.disabled = pagina == 1
	$VBox/Barra/BtnSiguiente.disabled = pagina == TOTAL_PAGINAS
	_zoom = 1.0
	_desplazamiento = Vector2.ZERO
	_acomodar()
	# Precargar las páginas vecinas para que el cambio sea inmediato
	for vecina in [pagina - 1, pagina + 1]:
		if vecina >= 1 and vecina <= TOTAL_PAGINAS:
			ResourceLoader.load_threaded_request(CARPETA % vecina)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right"):
		ir_a(pagina + 1)
	elif event.is_action_pressed("ui_left"):
		ir_a(pagina - 1)


## Ajusta la hoja al ancho del área, con el zoom y el desplazamiento actuales.
func _acomodar() -> void:
	if hoja.texture == null or area.size.x <= 0.0:
		return
	var proporcion := float(hoja.texture.get_height()) / hoja.texture.get_width()
	var base := Vector2(area.size.x, area.size.x * proporcion)
	if base.y > area.size.y:   # si no cabe a lo alto, se ajusta a la altura
		base = Vector2(area.size.y / proporcion, area.size.y)
	hoja.size = base * _zoom
	# Que la hoja no se salga dejando bordes vacíos
	var libre := (hoja.size - area.size) / 2.0
	_desplazamiento.x = clampf(_desplazamiento.x, -maxf(libre.x, 0.0), maxf(libre.x, 0.0))
	_desplazamiento.y = clampf(_desplazamiento.y, -maxf(libre.y, 0.0), maxf(libre.y, 0.0))
	hoja.position = (area.size - hoja.size) / 2.0 + _desplazamiento


func _hacer_zoom(nuevo: float, centro: Vector2) -> void:
	nuevo = clampf(nuevo, 1.0, ZOOM_MAXIMO)
	# Mantener quieto el punto que está bajo el dedo
	var desde_centro := centro - area.size / 2.0 - _desplazamiento
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
				ir_a(pagina + (1 if _arrastre_x < 0.0 else -1))   # deslizar a los lados cambia de página
	elif event is InputEventScreenDrag:
		if _toques.size() >= 2 and _toques.has(event.index):
			# Pellizcar: el zoom cambia según cuánto se separan los dedos
			var otro: Vector2 = _toques[_toques.keys().filter(func(k) -> bool: return k != event.index)[0]]
			var antes: float = otro.distance_to(_toques[event.index])
			_toques[event.index] = event.position
			var despues: float = otro.distance_to(event.position)
			if antes > 10.0:
				_hacer_zoom(_zoom * despues / antes, (otro + event.position) / 2.0)
		else:
			_toques[event.index] = event.position
			if _zoom > 1.01:
				_desplazamiento += event.relative
				_acomodar()
			else:
				_arrastre_x += event.relative.x
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_hacer_zoom(_zoom * 1.15, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_hacer_zoom(_zoom / 1.15, event.position)
	elif event is InputEventMagnifyGesture:
		_hacer_zoom(_zoom * event.factor, event.position)


func _mostrar_indice() -> void:
	var capa := Control.new()
	capa.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(capa)
	var sombra := ColorRect.new()
	sombra.color = Color(0, 0, 0, 0.6)
	sombra.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa.add_child(sombra)
	var panel := PanelContainer.new()
	capa.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 24
	panel.offset_right = -24
	panel.offset_top = 90
	panel.offset_bottom = -40
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 10)
	panel.add_child(columna)
	var titulo := Label.new()
	titulo.text = "Índice"
	titulo.add_theme_font_size_override("font_size", 30)
	titulo.add_theme_color_override("font_color", Color(1, 0.84, 0.3))
	columna.add_child(titulo)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columna.add_child(scroll)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 6)
	scroll.add_child(lista)
	for entrada in INDICE:
		var boton := Button.new()
		boton.text = "%s%s   ·  pág. %d" % ["      ".repeat(entrada[2]), entrada[0], entrada[1]]
		boton.alignment = HORIZONTAL_ALIGNMENT_LEFT
		boton.add_theme_font_size_override("font_size", 22 if entrada[2] < 2 else 20)
		if entrada[2] == 2:
			boton.flat = true
		boton.pressed.connect(func() -> void:
			ir_a(entrada[1])
			capa.queue_free())
		lista.add_child(boton)
	var cerrar := Button.new()
	cerrar.text = "Cerrar"
	cerrar.custom_minimum_size = Vector2(0, 64)
	cerrar.pressed.connect(capa.queue_free)
	columna.add_child(cerrar)


func _volver() -> void:
	if como_ventana:
		queue_free()
	else:
		get_tree().change_scene_to_file(Perfil.volver_a)
