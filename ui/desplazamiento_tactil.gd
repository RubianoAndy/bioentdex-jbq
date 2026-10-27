extends Node
## Autoload "DesplazamientoTactil": en el celular, las listas llenas de botones (tarjetas de
## especies, misiones, tienda...) no se podían deslizar porque el botón se quedaba con el dedo.
## Aquí, todo botón que esté dentro de un ScrollContainer deja pasar el toque a la lista, así se
## puede deslizar empezando sobre una tarjeta y el botón igual responde al tocarlo.
## Además, cada lista solo empieza a deslizarse cuando el dedo se mueve ZONA_MUERTA píxeles: al
## empezar a deslizar se cancela el botón tocado, y como el dedo siempre tiembla un poco, sin esto
## los botones de las listas (la guía, el índice, los enlaces de la ficha) casi nunca respondían.

const ZONA_MUERTA := 24


func _ready() -> void:
	get_tree().node_added.connect(_on_nodo_agregado)


func _on_nodo_agregado(nodo: Node) -> void:
	if nodo is ScrollContainer and nodo.scroll_deadzone < ZONA_MUERTA:
		nodo.scroll_deadzone = ZONA_MUERTA
		return
	if not nodo is BaseButton:
		return
	var padre := nodo.get_parent()
	while padre:
		if padre is ScrollContainer:
			(nodo as Control).mouse_filter = Control.MOUSE_FILTER_PASS
			return
		padre = padre.get_parent()
