class_name PaletaMapa
## Colores de la máscara del humedal (mapa/mascara_humedal.png).
## Para cambiar el mapa, pinta la máscara con estos colores exactos en cualquier editor de imágenes.
## Si agregas o cambias un color aquí, cámbialo también en mapa/suelo_humedal.gdshader.

enum { AGUA, JUNCAL, PASTO, BOSQUE, SENDERO, PRADERA, CIUDAD, FLOTANTES, TIERRA }

const COLORES := [
	Color8(40, 90, 200),    # AGUA
	Color8(40, 120, 60),    # JUNCAL
	Color8(120, 190, 80),   # PASTO
	Color8(20, 80, 40),     # BOSQUE
	Color8(160, 110, 60),   # SENDERO
	Color8(220, 200, 90),   # PRADERA
	Color8(130, 130, 130),  # CIUDAD
	Color8(60, 160, 160),   # FLOTANTES (buchón y lenteja de agua)
	Color8(100, 70, 40),    # TIERRA (camellones)
]


## Devuelve la clase (AGUA, JUNCAL...) del color más parecido de la paleta.
static func clase(color: Color) -> int:
	var mejor := PASTO
	var menor := INF
	for k in COLORES.size():
		var c: Color = COLORES[k]
		var d := Vector3(color.r - c.r, color.g - c.g, color.b - c.b).length_squared()
		if d < menor:
			menor = d
			mejor = k
	return mejor
