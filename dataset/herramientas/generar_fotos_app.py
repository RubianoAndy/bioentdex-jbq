# Genera dataset/fotos_app/<id_insecto>/ con copias livianas de las fotos reales para la app.
#
#   python dataset/herramientas/generar_fotos_app.py
#
# Lee dataset/insectos reales/indice.csv y toma las fotos que tienen "id_en_el_juego" y confianza alta o media.
# Las originales no se tocan (esa carpeta tiene .gdignore y Godot no la importa). Volver a ejecutarlo cada vez
# que cambie el índice: la carpeta fotos_app se rehace desde cero.
import csv, os, shutil
from PIL import Image, ImageOps

RAIZ = os.path.join(os.path.dirname(__file__), "..")
ORIGEN = os.path.join(RAIZ, "insectos reales")
DESTINO = os.path.join(RAIZ, "fotos_app")
LADO_MAXIMO = 1280

if os.path.isdir(DESTINO):
    shutil.rmtree(DESTINO)
contador = {}
with open(os.path.join(ORIGEN, "indice.csv"), encoding="utf-8-sig") as f:
    filas = [r for r in csv.DictReader(f) if r["id_en_el_juego"] and r["confianza"] in ("alta", "media")]
for r in sorted(filas, key=lambda r: (r["id_en_el_juego"], r["confianza"] != "alta", r["archivo"])):
    insecto = r["id_en_el_juego"]
    os.makedirs(os.path.join(DESTINO, insecto), exist_ok=True)
    contador[insecto] = contador.get(insecto, 0) + 1
    imagen = ImageOps.exif_transpose(Image.open(os.path.join(ORIGEN, r["archivo"])))
    imagen.thumbnail((LADO_MAXIMO, LADO_MAXIMO))
    transparente = imagen.mode in ("RGBA", "LA") and imagen.getchannel("A").getextrema()[0] < 250
    nombre = os.path.join(DESTINO, insecto, f"{insecto}_{contador[insecto]:02d}")
    if transparente:
        imagen.save(nombre + ".png")
    else:
        imagen.convert("RGB").save(nombre + ".jpg", quality=85)
for insecto in sorted(contador):
    print(f"{contador[insecto]:3d}  {insecto}")
print("total", sum(contador.values()))
