class_name CelebracionEvolucion
extends ColorRect
## "¡Evolución!": se muestra cuando un registro nuevo desbloquea otra fase del ciclo de vida de una
## especie. El modelo de la fase anterior destella y se transforma en el de la nueva, con una frase
## que explica ese cambio. Se cierra tocando la pantalla o sola después de unos segundos.
## La crea Recompensas al recibir RegistroEspecies.etapa_alcanzada.

const DORADO := Color(1, 0.84, 0.3)
const EXPLICACION := {
	"huevo": "Todo empieza con un huevo: la hembra los pone donde sus crías tendrán alimento.",
	"larva": "Del huevo sale la larva: come muchísimo y crece cambiando de piel varias veces.",
	"pupa": "La larva se convierte en pupa: por dentro, todo su cuerpo se transforma.",
	"ninfa": "Del huevo sale una ninfa: se parece al adulto, pero todavía no tiene alas.",
	"adulto": "¡Adulto! Ya puede volar y reproducirse, y el ciclo vuelve a empezar.",
}
const DURACION := 7.0

var especie: Especie
var anterior := ""
var nueva := ""

var _vista: VistaModelo3D
var _destello: ColorRect
var _textos: VBoxContainer
var _listo := false


func configurar(nueva_especie: Especie, etapa_anterior: String, etapa_nueva: String) -> CelebracionEvolucion:
	especie = nueva_especie
	anterior = etapa_anterior
	nueva = etapa_nueva
	return self


func _ready() -> void:
	color = Color(0.02, 0.06, 0.04, 0.93)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var columna := VBoxContainer.new()
	columna.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	columna.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_theme_constant_override("separation", 10)
	columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(columna)

	columna.add_child(_etiqueta("¡Evolución!", 52, DORADO))
	_vista = VistaModelo3D.new().configurar(especie, anterior if not anterior.is_empty() else nueva, 420.0)
	_vista.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	columna.add_child(_vista)

	_textos = VBoxContainer.new()
	_textos.add_theme_constant_override("separation", 8)
	_textos.modulate.a = 0.0
	columna.add_child(_textos)
	_textos.add_child(_etiqueta("Tu registro de %s llegó a la fase: %s" % [especie.nombre_comun, nueva], 30, Color.WHITE))
	_textos.add_child(_etiqueta(EXPLICACION.get(nueva.to_lower(), ""), 24, Color(0.85, 0.95, 0.88)))
	_textos.add_child(_etiqueta(" › ".join(especie.etapas_ciclo_vida), 22, DORADO))
	_textos.add_child(_etiqueta("Toca para continuar", 18, Color(1, 1, 1, 0.6)))

	_destello = ColorRect.new()
	_destello.color = Color(1, 1, 1, 0)
	_destello.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_destello.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_destello)
	_animar()


func _animar() -> void:
	modulate.a = 0.0
	await create_tween().tween_property(self, "modulate:a", 1.0, 0.3).finished
	if not anterior.is_empty():
		# El modelo anterior brilla y destella cada vez más rápido...
		await get_tree().create_timer(0.8).timeout
		for i in 4:
			var pulso := create_tween()
			pulso.tween_property(_vista, "modulate", Color(2.5, 2.5, 2.5), 0.12 - i * 0.02)
			pulso.tween_property(_vista, "modulate", Color.WHITE, 0.12 - i * 0.02)
			await pulso.finished
		# ...y en un destello blanco se transforma en la nueva fase
		await create_tween().tween_property(_destello, "color:a", 1.0, 0.15).finished
		_vista.cambiar_etapa(nueva)
		_vista.pivot_offset = _vista.size / 2.0
		_vista.scale = Vector2(0.4, 0.4)
		create_tween().tween_property(_destello, "color:a", 0.0, 0.5)
		create_tween().tween_property(_vista, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_confeti()
	create_tween().tween_property(_textos, "modulate:a", 1.0, 0.4)
	_listo = true
	await get_tree().create_timer(DURACION).timeout
	_cerrar()


func _gui_input(event: InputEvent) -> void:
	if _listo and event is InputEventMouseButton and event.pressed:
		_cerrar()


func _cerrar() -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	_listo = false
	var salida := create_tween()
	salida.tween_property(self, "modulate:a", 0.0, 0.3)
	salida.tween_callback(queue_free)


func _confeti() -> void:
	var confeti := CPUParticles2D.new()
	confeti.position = Vector2(size.x / 2.0, size.y * 0.42)
	confeti.amount = 70
	confeti.one_shot = true
	confeti.explosiveness = 1.0
	confeti.lifetime = 1.8
	confeti.spread = 180.0
	confeti.initial_velocity_min = 300.0
	confeti.initial_velocity_max = 750.0
	confeti.gravity = Vector2(0, 700)
	confeti.scale_amount_min = 6.0
	confeti.scale_amount_max = 12.0
	confeti.color_ramp = Gradient.new()
	confeti.color_ramp.colors = PackedColorArray([DORADO, Color(0.45, 0.9, 0.6), Color(1, 1, 1, 0)])
	add_child(confeti)
	confeti.emitting = true


func _etiqueta(texto: String, tamano: int, color_texto: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.custom_minimum_size = Vector2(640, 0)
	etiqueta.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	etiqueta.add_theme_font_size_override("font_size", tamano)
	etiqueta.add_theme_color_override("font_color", color_texto)
	etiqueta.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	etiqueta.add_theme_constant_override("outline_size", 6)
	return etiqueta
