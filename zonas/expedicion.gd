extends Node
## Autoload "Expedicion": zonas del humedal y estado del recorrido al cambiar de escena.

const CARPETA_ZONAS := "res://zonas/datos/"
const POSICION_INICIAL := Vector3(20.8, 0, 32.0)   # entrada desde la plazoleta, al sureste
const MASCARA := preload("res://mapa/mascara_humedal.png")
const TAMANO_MAPA := Vector2(200, 200)            # tamaño del Suelo en MapaExpedicion.tscn
const VEGETACION := preload("res://mapa/vegetacion.gd")
const ESCENA_MAPA := "res://MapaExpedicion.tscn"

var zonas: Array[Zona] = []
var zona_actual: Zona = null
var posicion_explorador := POSICION_INICIAL   # para volver al mismo punto al salir de una zona

# Terreno y vegetación se calculan una sola vez, en otro hilo, desde que abre la app.
# Así entrar al mapa (o volver de una zona) no congela la pantalla en el celular.
var _terreno: Terreno
var _vegetacion := {}
var _tarea_mapa := -1
var _escena_mapa: PackedScene   # se guarda para no volver a cargarla en cada entrada
var ruido_suelo: NoiseTexture2D   # textura del suelo del mapa: generarla tarda, se hace una vez


func _ready() -> void:
	for archivo in ResourceLoader.list_directory(CARPETA_ZONAS):
		if archivo.ends_with(".tres"):
			var zona := load(CARPETA_ZONAS + archivo) as Zona
			if zona:
				zonas.append(zona)
	_tarea_mapa = WorkerThreadPool.add_task(_calcular_mapa.bind(MASCARA.get_image()), false, "Calcular mapa")
	ResourceLoader.load_threaded_request(ESCENA_MAPA)   # la escena y sus scripts también, en segundo plano
	ruido_suelo = NoiseTexture2D.new()
	ruido_suelo.seamless = true
	ruido_suelo.noise = FastNoiseLite.new()


func _calcular_mapa(imagen: Image) -> void:
	_terreno = Terreno.new(imagen, TAMANO_MAPA)
	_vegetacion = VEGETACION.calcular(_terreno, zonas)


## Terreno ya calculado (espera si el cálculo aún no termina) y las plantas para la Vegetacion.
func datos_mapa() -> Array:
	if _tarea_mapa >= 0:
		WorkerThreadPool.wait_for_task_completion(_tarea_mapa)
		_tarea_mapa = -1
	if _escena_mapa == null:
		_escena_mapa = ResourceLoader.load_threaded_get(ESCENA_MAPA)
	return [_terreno, _vegetacion]


func entrar_a_zona(zona: Zona, posicion: Vector3) -> void:
	zona_actual = zona
	posicion_explorador = posicion
	get_tree().change_scene_to_file("res://ZonaInterior.tscn")


func volver_al_mapa() -> void:
	get_tree().change_scene_to_file(ESCENA_MAPA)
