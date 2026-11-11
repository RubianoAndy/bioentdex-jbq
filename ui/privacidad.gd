class_name Privacidad
extends RefCounted
## Mensajes de privacidad compartidos por las pantallas de exportación.


static func advertencia_tarjeta() -> String:
	return "Privacidad: elige una foto sin nombres reales, rostros, ubicaciones ni otros datos personales. La imagen se guarda solo en este dispositivo."


static func aviso_analitica() -> String:
	return "Analítica local del aprendizaje: solo contadores agregados, sin nombres, rostros, texto libre, fechas ni identificadores. No se envía información a internet. Los datos de una instalación no son anónimos de forma absoluta."


static func limite_pin() -> String:
	return "El PIN es una barrera local limitada: el APK y sus archivos pueden inspeccionarse o modificarse. No ofrece autenticación fuerte."
