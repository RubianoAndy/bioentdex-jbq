# Genera mapa/mascara_humedal.png desde cero (humedal bogotano alargado, rodeado de ciudad).
# OJO: sobrescribe la máscara. Úsalo solo para empezar de nuevo; los ajustes finos se pueden
# hacer pintando la máscara directamente con los colores de mapa/paleta_mapa.gd.
#
#   python mapa/herramientas/generar_mascara.py
#
# Imprime también la posición en el mapa (x, z) de cada zona, para copiarla a zonas/datos/*.tres.
import os
import numpy as np
from PIL import Image

N = 512               # resolución de la máscara
TAM_MAPA = 160.0      # tamaño del mapa en Godot (debe coincidir con el Suelo de MapaExpedicion.tscn)

AGUA = (40, 90, 200); JUNCAL = (40, 120, 60); PASTO = (120, 190, 80); BOSQUE = (20, 80, 40)
SENDERO = (160, 110, 60); PRADERA = (220, 200, 90); CALLE = (130, 130, 130); FLOTANTES = (60, 160, 160)
TIERRA = (100, 70, 40); PUENTE = (200, 160, 110); MANZANA = (200, 60, 60); KIKUYO = (180, 190, 40)
BASURAL = (120, 100, 120)
NOMBRES = {AGUA: "agua", JUNCAL: "juncal", PASTO: "pasto", BOSQUE: "bosque", SENDERO: "sendero",
           PRADERA: "pradera", CALLE: "calle", FLOTANTES: "flotantes", TIERRA: "tierra", PUENTE: "puente",
           MANZANA: "manzana", KIKUYO: "kikuyo", BASURAL: "basural"}

# Todo se diseña en coordenadas de 0 a 256 (x a la derecha, y hacia abajo = sur)
ys, xs = np.mgrid[0:N, 0:N]
u = (xs + 0.5) * 256 / N
v = (ys + 0.5) * 256 / N
img = np.zeros((N, N, 3), np.uint8)

EJE = np.array([0.754, -0.657])     # dirección del humedal (suroeste -> noreste)
PERP = np.array([0.657, 0.754])     # perpendicular (hacia el sureste)
CENTRO = [(30, 215), (80, 170), (125, 135), (170, 100), (225, 45)]   # línea central del humedal


def distancia_linea(pts):
    d = np.full(u.shape, 1e9)
    for (x1, y1), (x2, y2) in zip(pts, pts[1:]):
        px, py = x2 - x1, y2 - y1
        t = np.clip(((u - x1) * px + (v - y1) * py) / (px * px + py * py), 0, 1)
        d = np.minimum(d, np.hypot(u - (x1 + t * px), v - (y1 + t * py)))
    return d


def linea(pts, ancho):
    return distancia_linea(pts) < ancho


def elipse(cx, cy, ra, rb, s, amp=0.12):
    """Mancha ovalada irregular, alargada en la dirección del humedal."""
    dx, dy = u - cx, v - cy
    a = (dx * EJE[0] + dy * EJE[1]) / ra
    b = (dx * PERP[0] + dy * PERP[1]) / rb
    ang = np.arctan2(b, a)
    k = 1 + amp * (np.sin(3 * ang + s) * 0.6 + np.sin(5 * ang + s * 2.1) * 0.3 + np.sin(9 * ang + s * 0.7) * 0.15)
    return np.hypot(a, b) < k


def circulo(cx, cy, r):
    return elipse(cx, cy, r, r, cx * 0.1, 0.15)


def punto(p, desplazamiento_perp=0.0):
    return (p[0] + PERP[0] * desplazamiento_perp, p[1] + PERP[1] * desplazamiento_perp)


# 1. Ciudad: manzanas con calles en cuadrícula
img[:] = MANZANA
img[((u % 20) < 3) | ((v % 20) < 3)] = CALLE

# 2. Ronda arborizada del río Bogotá (esquina suroeste)
RIO = [(0, 175), (15, 215), (45, 256)]
d_rio = distancia_linea(RIO)
img[d_rio < 16] = BOSQUE

# 3. Cuerpo del humedal: pasto, ronda hídrica (árboles), sendero perimetral y avenida
d_eje = distancia_linea(CENTRO)
a_lo_largo = (u - 30) * EJE[0] + (v - 215) * EJE[1]
ancho = 40 + 5 * np.sin(a_lo_largo * 0.045 + 1)
img[d_eje < ancho + 6] = CALLE                                   # avenida que bordea el humedal
img[d_eje < ancho + 2] = SENDERO                                 # sendero perimetral
img[d_eje < ancho - 1] = BOSQUE                                  # ronda hídrica
claros = np.sin(a_lo_largo * 0.11) < -0.75                       # claros en la ronda
img[(d_eje < ancho - 13) | ((d_eje < ancho - 1) & claros)] = PASTO

# 4. Corredor ambiental: franja verde que sale del humedal hacia el norte
CORREDOR = [punto((170, 100), -36), punto((170, 100), -140)]
d_cor = distancia_linea(CORREDOR)
img[(d_cor < 8) & (d_eje > ancho - 8)] = BOSQUE
img[(d_cor < 5.5) & (d_eje > ancho - 8)] = PASTO
img[(d_cor < 1.4) & (d_eje > ancho - 8)] = SENDERO

# 5. Manchas especiales: kikuyo invasor, compost, basural, pradera de los monolitos y pradera terrestre
Z = {
    "neofita": punto((80, 170), 20),
    "materia_organica": punto((198, 72), 22),
    "basuras": punto((45, 200), 18),
    "monolitos": punto((150, 117), -24),
    "terrestre": punto((150, 117), 18),
}
img[circulo(*Z["neofita"], 11)] = KIKUYO
img[circulo(*Z["materia_organica"], 7)] = TIERRA
img[circulo(*Z["basuras"], 8)] = BASURAL
img[circulo(*Z["monolitos"], 6)] = PRADERA
img[circulo(*Z["terrestre"], 10)] = PRADERA

# 6. Agua: tres espejos de agua unidos por un canal, con su franja de juncos (zona de transición)
LAGOS = [((70, 178), 22, 13, 0.4), ((128, 132), 30, 18, 1.0), ((185, 88), 22, 13, 2.2)]
CANAL = [(22, 222), (45, 200), (70, 178), (80, 170), (125, 135), (170, 100), (185, 88)]
for (c, ra, rb, s) in LAGOS:
    img[elipse(*c, ra * 1.35, rb * 1.35, s)] = JUNCAL
img[linea(CANAL, 8)] = JUNCAL
lagos = np.zeros(u.shape, bool)
for (c, ra, rb, s) in LAGOS:
    lagos |= elipse(*c, ra, rb, s)
lagos |= linea(CANAL, 2.5)
img[lagos] = AGUA
img[lagos & elipse(70, 178, 18, 11, 0.9, 0.25)] = FLOTANTES     # lago cubierto de buchón
img[lagos & elipse(142, 122, 10, 7, 1.7, 0.3)] = FLOTANTES
img[lagos & elipse(196, 80, 8, 6, 0.3, 0.3)] = FLOTANTES

# 7. Río Bogotá (y puentes donde lo cruza el sendero)
rio = d_rio < 6
img[rio] = AGUA
img[rio & (np.abs(d_eje - (ancho + 0.5)) < 1.5)] = PUENTE

# 8. Puentes de madera: muelle al lago grande y dos pasarelas que cruzan el humedal
L2 = (128, 132)
img[linea([L2, punto(L2, 30)], 1.4)] = PUENTE
img[linea([punto(L2, 30), punto(L2, 48)], 1.4)] = SENDERO        # el muelle sigue como sendero
for p in [(99, 155), (156, 110)]:
    img[linea([punto(p, -50), punto(p, 50)], 1.4) & (d_eje < ancho - 1)] = PUENTE

# 9. Entrada desde la ciudad: plazoleta y camino hasta el muelle
PLAZA = punto((125, 135), 52)
img[linea([PLAZA, punto(L2, 30)], 1.4) & (d_eje > ancho - 1)] = SENDERO
img[circulo(*PLAZA, 6)] = CALLE

Image.fromarray(img).save(os.path.join(os.path.dirname(__file__), "..", "mascara_humedal.png"))

# Posiciones de las zonas (en el mapa de Godot) y verificación de que se puede caminar ahí
ZONAS = {
    "agua_abierta": punto(L2, 6),
    "transicion": (99, 155),
    "neofita": Z["neofita"],
    "terrestre": Z["terrestre"],
    "ronda_hidrica": punto((125, 135), -35),
    "avistamiento_aves": punto((185, 88), -20),
    "materia_organica": Z["materia_organica"],
    "basuras": Z["basuras"],
    "monolitos": Z["monolitos"],
    "urbana": PLAZA,
    "corredor_ambiental": punto(CORREDOR[0], -14),
    "INICIO": punto(PLAZA, -7),
}
for nombre, (px, py) in ZONAS.items():
    clase = NOMBRES.get(tuple(img[int(py * N / 256), int(px * N / 256)]), "?")
    x, z = (px / 256 - 0.5) * TAM_MAPA, (py / 256 - 0.5) * TAM_MAPA
    print(f"{nombre:20s} Vector2({x:.1f}, {z:.1f})   suelo: {clase}")
