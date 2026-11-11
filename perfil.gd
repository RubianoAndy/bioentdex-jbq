extends Node
## Autoload "Perfil": nombre y apariencia del explorador. Se guarda en user://perfil.cfg.

const ARCHIVO := "user://perfil.cfg"

const PIELES := [Color(0.98, 0.84, 0.7), Color(0.87, 0.67, 0.5), Color(0.76, 0.56, 0.42), Color(0.58, 0.4, 0.28), Color(0.4, 0.27, 0.18)]
const CAMISAS := [Color(0.78, 0.68, 0.45), Color(0.25, 0.5, 0.35), Color(0.2, 0.4, 0.7), Color(0.85, 0.35, 0.3), Color(0.95, 0.75, 0.2), Color(0.55, 0.35, 0.65)]
const PANTALONES := [Color(0.3, 0.27, 0.22), Color(0.2, 0.25, 0.4), Color(0.45, 0.38, 0.28), Color(0.15, 0.15, 0.15), Color(0.35, 0.42, 0.3)]
const SOMBREROS := ["Sombrero", "Gorra", "Sin sombrero"]
const COLORES_SOMBRERO := [Color(0.55, 0.42, 0.24), Color(0.25, 0.42, 0.3), Color(0.85, 0.3, 0.25), Color(0.2, 0.35, 0.65), Color(0.95, 0.9, 0.8)]
const GENEROS := ["Masculino", "Femenino"]
const CABELLOS := [Color(0.1, 0.08, 0.07), Color(0.26, 0.15, 0.08), Color(0.46, 0.28, 0.14), Color(0.86, 0.68, 0.36), Color(0.62, 0.26, 0.12)]
const MOCHILAS := [Color(0.25, 0.42, 0.3), Color(0.8, 0.45, 0.2), Color(0.2, 0.35, 0.65), Color(0.6, 0.2, 0.25), Color(0.35, 0.35, 0.35)]

var nombre := "Explorador"
var genero := 0       # índice en GENEROS
var piel := 2
var cabello := 0
var camisa := 5
var pantalon := 1
var sombrero := 2
var color_sombrero := 0
var mochila := 0

## Escena a la que vuelve la pantalla de personalizar (el menú o el mapa)
var volver_a := "res://MenuPrincipal.tscn"


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(ARCHIVO) != OK:
		return
	for clave in ["nombre", "genero", "piel", "cabello", "camisa", "pantalon", "sombrero", "color_sombrero", "mochila"]:
		set(clave, cfg.get_value("perfil", clave, get(clave)))


func guardar() -> void:
	var cfg := ConfigFile.new()
	for clave in ["nombre", "genero", "piel", "cabello", "camisa", "pantalon", "sombrero", "color_sombrero", "mochila"]:
		cfg.set_value("perfil", clave, get(clave))
	cfg.save(ARCHIVO)
