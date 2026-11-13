extends Node3D
## Animación sencilla de los modelos 3D procedurales (ModeloProcedural): las alas ("AlaIzq*" /
## "AlaDer*") aletean según su meta "aleteo" (amplitud) y "rapidez", y los animales con meta
## "flota" (colibrí, pez) suben y bajan suavemente. Los modelos .glb usan su propio AnimationPlayer.

var _alas: Array[Node3D] = []
var _base: Array[Vector3] = []
var _tiempo := randf() * 10.0
var _alto_flota := 0.0


func _ready() -> void:
	for hijo in get_children():
		if hijo.has_meta("aleteo"):
			_alas.append(hijo)
			_base.append(hijo.rotation)
	_alto_flota = get_meta("flota", 0.0)


func _process(delta: float) -> void:
	_tiempo += delta
	for i in _alas.size():
		var ala := _alas[i]
		var lado := 1.0 if ala.name.begins_with("AlaIzq") else -1.0
		var giro: float = sin(_tiempo * float(ala.get_meta("rapidez"))) * float(ala.get_meta("aleteo"))
		ala.rotation = _base[i] + Vector3(0, 0, giro * lado)
	if _alto_flota > 0.0:
		position.y = _alto_flota + sin(_tiempo * 2.0) * 0.08
