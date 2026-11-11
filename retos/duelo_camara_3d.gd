class_name DueloCamara3D
extends Node3D
## Mueve la cámara entre el plano general y los enfoques de atacante/defensor.

@onready var camara: Camera3D = $Camera3D

var plano_general := Vector3(0, 5.7, 9.2)


func enfocar(atacante: Node3D, defensor: Node3D) -> void:
	var destino := atacante.global_position + Vector3(0, 2.2, 4.8)
	var objetivo := defensor.global_position + Vector3(0, 1.1, 0)
	_mover(destino, objetivo)


func reaccionar(defensor: Node3D, atacante: Node3D) -> void:
	var destino := defensor.global_position + Vector3(0, 2.0, 4.0)
	var objetivo := atacante.global_position + Vector3(0, 1.2, 0)
	_mover(destino, objetivo)


func restablecer() -> void:
	_mover(plano_general, Vector3(0, 1.0, -0.5))


func _mover(posicion: Vector3, objetivo: Vector3) -> void:
	var transformacion := Transform3D(Basis.looking_at(objetivo - posicion, Vector3.UP), posicion)
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camara, "position", posicion, 0.55)
	tween.parallel().tween_property(camara, "rotation", transformacion.basis.get_euler(), 0.55)
