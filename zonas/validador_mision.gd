class_name ValidadorMision
extends RefCounted
## Comprueba conceptos obligatorios sin depender de mayúsculas, tildes o puntuación.


static func conceptos_faltantes(texto: String, obligatorios: PackedStringArray) -> PackedStringArray:
	var faltantes := PackedStringArray()
	var respuesta := " " + normalizar(texto) + " "
	for concepto in obligatorios:
		var clave := normalizar(concepto)
		if not clave.is_empty() and not respuesta.contains(" " + clave + " "):
			faltantes.append(concepto)
	return faltantes


static func normalizar(texto: String) -> String:
	var resultado := texto.to_lower()
	var reemplazos := {
		"á": "a", "à": "a", "ä": "a", "â": "a",
		"é": "e", "è": "e", "ë": "e", "ê": "e",
		"í": "i", "ì": "i", "ï": "i", "î": "i",
		"ó": "o", "ò": "o", "ö": "o", "ô": "o",
		"ú": "u", "ù": "u", "ü": "u", "û": "u",
		"ñ": "n",
	}
	for letra in reemplazos:
		resultado = resultado.replace(letra, reemplazos[letra])
	var separadores := RegEx.new()
	separadores.compile("[^a-z0-9]+")
	return separadores.sub(resultado, " ", true).strip_edges()
