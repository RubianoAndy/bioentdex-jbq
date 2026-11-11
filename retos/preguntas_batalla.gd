class_name PreguntasBatalla
## Preguntas de las batallas contra los depredadores. Cada respuesta correcta lanza un poder.
## "tema" decide con qué depredador sale más: ave, anfibio, mamifero o general (con todos).
## Para agregar una pregunta, copia una línea: la respuesta correcta es la de la posición "correcta".

const PREGUNTAS := [
	# --- Generales: cadenas alimenticias, insectos y cuidado del humedal ---
	{"tema": "general", "pregunta": "¿Qué es un depredador?",
		"opciones": ["Un animal que caza a otros para alimentarse", "Una planta que crece muy rápido", "Un insecto que poliniza flores"],
		"correcta": 0, "explicacion": "Los depredadores cazan a otros animales (sus presas). No son malos: mantienen el equilibrio del humedal."},
	{"tema": "general", "pregunta": "Si desaparecieran los insectos del humedal, ¿qué les pasaría a las aves que los comen?",
		"opciones": ["Nada, comerían piedras", "Tendrían menos alimento y habría menos aves", "Habría más aves"],
		"correcta": 1, "explicacion": "En una cadena alimenticia todo está conectado: sin insectos, las aves insectívoras pasan hambre."},
	{"tema": "general", "pregunta": "¿Qué hacen los abejorros y las abejas por las plantas?",
		"opciones": ["Las polinizan al llevar polen de flor en flor", "Se comen sus raíces", "Les quitan el agua"],
		"correcta": 0, "explicacion": "Al buscar néctar llevan polen de una flor a otra, y así las plantas pueden formar frutos y semillas."},
	{"tema": "general", "pregunta": "¿Dónde vive la libélula cuando es joven (ninfa)?",
		"opciones": ["Dentro de los árboles", "Bajo el agua", "En las nubes"],
		"correcta": 1, "explicacion": "Las ninfas de libélula viven bajo el agua cazando otros animalitos; por eso necesitan humedales limpios."},
	{"tema": "general", "pregunta": "¿Por qué el zancudo pone sus huevos en agua quieta?",
		"opciones": ["Porque le gusta nadar", "Porque sus larvas crecen en el agua", "Para esconderlos de la lluvia"],
		"correcta": 1, "explicacion": "Las larvas del zancudo viven en el agua quieta. Los peces, ranas y ninfas de libélula se las comen."},
	{"tema": "general", "pregunta": "¿Cuántas patas tiene un insecto adulto?",
		"opciones": ["Cuatro", "Seis", "Ocho"],
		"correcta": 1, "explicacion": "Todos los insectos adultos tienen seis patas, unidas a la parte media del cuerpo (el tórax)."},
	{"tema": "general", "pregunta": "¿Cuál de estos animales NO es un insecto?",
		"opciones": ["La mariquita", "La hormiga", "La araña"],
		"correcta": 2, "explicacion": "La araña es un arácnido: tiene ocho patas y no tiene antenas ni alas."},
	{"tema": "general", "pregunta": "¿Por qué la mariquita es amiga de las plantas?",
		"opciones": ["Porque come pulgones que les chupan la savia", "Porque les da sombra", "Porque riega las hojas"],
		"correcta": 0, "explicacion": "Las mariquitas son depredadoras de pulgones: un control natural de plagas, sin venenos."},
	{"tema": "general", "pregunta": "¿Cómo se llaman los organismos que descomponen hojas y restos, y devuelven nutrientes al suelo?",
		"opciones": ["Depredadores", "Descomponedores", "Polinizadores"],
		"correcta": 1, "explicacion": "Lombrices, hongos y muchos insectos son descomponedores: reciclan la materia del humedal."},
	{"tema": "general", "pregunta": "¿Qué es una cadena alimenticia?",
		"opciones": ["Una fila de animales caminando", "El camino de la energía cuando unos seres vivos se comen a otros", "Una cadena para amarrar animales"],
		"correcta": 1, "explicacion": "Ejemplo: la planta alimenta al insecto, el insecto a la rana y la rana a la garza."},
	{"tema": "general", "pregunta": "¿Qué pasa cuando botamos basura al humedal?",
		"opciones": ["Contamina el agua y daña el hogar de los animales", "Sirve de comida a los peces", "Ayuda a que crezcan las plantas"],
		"correcta": 0, "explicacion": "La basura tapa los canales, contamina el agua y los animales pueden enredarse o comer plásticos."},
	{"tema": "general", "pregunta": "¿Para qué le sirven las antenas a un insecto?",
		"opciones": ["Para oler y sentir lo que hay a su alrededor", "Para volar más rápido", "Para comer"],
		"correcta": 0, "explicacion": "Con las antenas perciben olores, vibraciones y hasta la humedad del aire."},

	# --- Aves ---
	{"tema": "ave", "pregunta": "¿Cómo ayudan las aves que comen insectos al humedal?",
		"opciones": ["Evitan que haya demasiados insectos", "Ensucian el agua", "No ayudan en nada"],
		"correcta": 0, "explicacion": "Las aves insectívoras regulan las poblaciones de insectos: son un control natural."},
	{"tema": "ave", "pregunta": "¿Por qué la garza blanca camina despacio en el agua poco profunda?",
		"opciones": ["Porque está cansada", "Para sorprender a peces, ranas e insectos", "Porque no sabe volar"],
		"correcta": 1, "explicacion": "La garza acecha quieta y lanza su pico largo y afilado en un instante."},
	{"tema": "ave", "pregunta": "¿Qué ave endémica de la sabana de Bogotá vive en los juncales y está en peligro?",
		"opciones": ["La tingua bogotana", "La paloma", "El loro amazónico"],
		"correcta": 0, "explicacion": "La tingua bogotana solo vive en estos humedales; si perdemos los juncales, la perdemos a ella."},
	{"tema": "ave", "pregunta": "¿Qué come el copetón?",
		"opciones": ["Solo carne", "Semillas, frutos e insectos", "Solo néctar"],
		"correcta": 1, "explicacion": "El copetón es omnívoro: come semillas, frutos pequeños e insectos, sobre todo cuando alimenta a sus polluelos."},
	{"tema": "ave", "pregunta": "¿Por qué las aves necesitan los árboles de la ronda del humedal?",
		"opciones": ["Para hacer nidos, descansar y refugiarse", "Para afilar el pico", "No los necesitan"],
		"correcta": 0, "explicacion": "Alisos y sauces son el hogar de muchas aves: allí anidan y se protegen."},
	{"tema": "ave", "pregunta": "¿Qué le pasa a un ave si come insectos envenenados con pesticidas?",
		"opciones": ["Se vuelve más fuerte", "Puede enfermar o morir", "Nada"],
		"correcta": 1, "explicacion": "Los venenos pasan por la cadena alimenticia: dañan a quien se come a los insectos."},

	# --- Anfibios ---
	{"tema": "anfibio", "pregunta": "¿Cómo atrapa la rana a los insectos?",
		"opciones": ["Con su lengua pegajosa que lanza muy rápido", "Con las patas de atrás", "Con una red"],
		"correcta": 0, "explicacion": "La lengua de la rana sale en una fracción de segundo y el insecto queda pegado."},
	{"tema": "anfibio", "pregunta": "¿Dónde crecen los renacuajos?",
		"opciones": ["En la tierra seca", "En el agua", "En los árboles"],
		"correcta": 1, "explicacion": "Los renacuajos viven en el agua y respiran por branquias hasta convertirse en ranas."},
	{"tema": "anfibio", "pregunta": "¿Por qué se dice que las ranas muestran si un humedal está sano?",
		"opciones": ["Porque cantan más fuerte", "Porque su piel delgada absorbe la contaminación", "Porque cambian de color"],
		"correcta": 1, "explicacion": "Su piel deja pasar agua y aire... y también contaminantes. Si hay ranas, el agua suele estar bien."},
	{"tema": "anfibio", "pregunta": "¿Qué comen principalmente las ranas adultas?",
		"opciones": ["Hierba", "Insectos y otros animalitos", "Semillas"],
		"correcta": 1, "explicacion": "Las ranas adultas son depredadoras de insectos, arañas y lombrices."},

	# --- Mamíferos ---
	{"tema": "mamifero", "pregunta": "La rata parda del humedal es una especie…",
		"opciones": ["Nativa de la sabana", "Introducida: llegó con los humanos", "En peligro de extinción"],
		"correcta": 1, "explicacion": "La rata parda vino de otros continentes en barcos y compite con los animales nativos."},
	{"tema": "mamifero", "pregunta": "¿Por qué hay más ratas donde hay basura?",
		"opciones": ["Porque encuentran comida y refugio fácil", "Porque les gusta el olor a flores", "Por casualidad"],
		"correcta": 0, "explicacion": "Recoger la basura es la mejor forma de que no haya tantas ratas."},
	{"tema": "mamifero", "pregunta": "La chucha (zarigüeya) es un…",
		"opciones": ["Roedor, como la rata", "Marsupial: carga a sus crías en una bolsa", "Reptil"],
		"correcta": 1, "explicacion": "Es el único marsupial de la sabana. Come insectos, frutos y hasta garrapatas: ¡es una aliada!"},
	{"tema": "mamifero", "pregunta": "¿A qué hora sale la chucha a buscar comida?",
		"opciones": ["Al mediodía", "De noche", "Nunca sale"],
		"correcta": 1, "explicacion": "La chucha es nocturna: de día duerme escondida entre árboles o techos."},
]

## Preguntas de relaciones ecológicas; la habilidad elegida decide qué concepto se practica.
const RELACIONES_ECOLOGICAS := [
	{"habilidad": "polen", "pregunta": "¿Qué relación ayuda a explicar que el abejorro visite flores y que la planta produzca semillas?",
		"opciones": ["El abejorro protege a la planta del agua", "Al buscar néctar, el abejorro transporta polen entre flores", "La flor se alimenta de las alas del abejorro"],
		"correcta": 1, "tema": "polinizacion", "explicacion": "La polinización conecta el alimento del polinizador con la reproducción de la planta."},
	{"habilidad": "polen", "pregunta": "Si disminuyen las flores nativas de la ronda, ¿qué efecto puede tener en abejorros y colibríes?",
		"opciones": ["Pueden perder fuentes de néctar y polen", "Aumenta el oxígeno del agua de forma inmediata", "No cambia su acceso al alimento"],
		"correcta": 0, "tema": "polinizacion", "explicacion": "La flora ofrece alimento; conservar diversidad vegetal sostiene a quienes la visitan."},
	{"habilidad": "polen", "pregunta": "¿Por qué un corredor con flores y arbustos puede ayudar a los polinizadores?",
		"opciones": ["Impide que cualquier insecto se mueva", "Reemplaza todas las plantas del humedal", "Conecta lugares de alimentación y refugio"],
		"correcta": 2, "tema": "conectividad", "explicacion": "Los corredores conectan parches de hábitat y recursos a través del paisaje."},
	{"habilidad": "control", "pregunta": "¿Cómo se relacionan las mariquitas, los pulgones y las plantas?",
		"opciones": ["La planta caza mariquitas para obtener agua", "La mariquita depreda pulgones que consumen savia", "El pulgón poliniza a la mariquita"],
		"correcta": 1, "tema": "biodiversidad_humedal", "explicacion": "La depredación puede regular poblaciones de herbívoros; es una interacción de la red trófica."},
	{"habilidad": "control", "pregunta": "Si desaparecen insectos acuáticos que comen las ninfas de libélula, ¿qué cambia primero en esa relación?",
		"opciones": ["Las plantas dejan de necesitar luz", "Las aves se convierten en plantas", "Las ninfas pierden parte de su alimento y la red trófica se altera"],
		"correcta": 2, "tema": "biodiversidad_humedal", "explicacion": "Los organismos se conectan por alimentación; un cambio puede propagarse a otros niveles."},
	{"habilidad": "control", "pregunta": "¿Por qué encontrar ninfas de libélula puede aportar información sobre el humedal?",
		"opciones": ["Demuestra que el agua nunca cambia", "Su ciclo incluye una fase acuática sensible a las condiciones del agua", "Solo viven en árboles secos"],
		"correcta": 1, "tema": "agua_ecosistemas", "explicacion": "Las observaciones de organismos y su hábitat aportan indicios, pero no son por sí solas un diagnóstico completo."},
	{"habilidad": "control", "pregunta": "¿Qué resultado puede tener la basura en un microhábitat de orilla?",
		"opciones": ["Alterar refugios y afectar organismos que usan agua y vegetación", "Crear siempre sitios seguros para toda la fauna", "Mejorar automáticamente la calidad del agua"],
		"correcta": 0, "tema": "residuos_humedal", "explicacion": "La contaminación puede modificar las condiciones del microhábitat y afectar varias especies."},
]


static func relacionales() -> Array:
	var preguntas := RELACIONES_ECOLOGICAS.duplicate(true)
	var anterior := RegistroEspecies.ultima_pregunta_batalla()
	if preguntas.size() > 1 and not anterior.is_empty():
		var sin_anterior := preguntas.filter(func(p: Dictionary) -> bool:
			return p.pregunta != anterior and id_estable(p) != anterior)
		if not sin_anterior.is_empty():
			preguntas = sin_anterior
	return preguntas


## Preguntas para una batalla contra ese depredador: primero las de su tema, mezcladas con generales.
static func para(depredador: Especie) -> Array:
	var tema := tema_de(depredador)
	var propias := PREGUNTAS.filter(func(p: Dictionary) -> bool: return p.tema == tema and tema != "general")
	var generales := PREGUNTAS.filter(func(p: Dictionary) -> bool: return p.tema == "general")
	propias.shuffle()
	generales.shuffle()
	# Intercala: una del tema del depredador, una general...
	var lista := []
	while not propias.is_empty() or not generales.is_empty():
		if not propias.is_empty():
			lista.append(propias.pop_back())
		if not generales.is_empty():
			lista.append(generales.pop_back())
	var anterior := RegistroEspecies.ultima_pregunta_batalla()
	if lista.size() > 1 and not anterior.is_empty():
		var sin_anterior := lista.filter(func(p: Dictionary) -> bool:
			return p.pregunta != anterior and id_estable(p) != anterior)
		if not sin_anterior.is_empty():
			lista = sin_anterior
	return lista


static func tema_de(depredador: Especie) -> String:
	match depredador.tipo:
		Especie.Tipo.AVE: return "ave"
		Especie.Tipo.ANFIBIO: return "anfibio"
		Especie.Tipo.MAMIFERO: return "mamifero"
	return "general"


## El ID usa el tema y el contenido de respuesta/explicación, nunca el enunciado visible.
static func id_estable(pregunta: Dictionary) -> String:
	var id := str(pregunta.get("id", ""))
	if not id.is_empty():
		return id
	var opciones: Array = pregunta.get("opciones", [])
	var indice_correcto := int(pregunta.get("correcta", -1))
	var tema := str(pregunta.get("tema", "general"))
	var clave := "%s|%d|%s|%s" % [tema, indice_correcto, str(opciones), str(pregunta.get("explicacion", ""))]
	return "pregunta:%s:%s" % [tema, str(clave.hash())]
