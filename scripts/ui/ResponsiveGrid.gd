class_name ResponsiveGrid
extends GridContainer
# ============================================================================
# ResponsiveGrid: rejilla que reparte las tarjetas en varias columnas segun el
# ancho REAL del que dispone (el de su ScrollContainer), en lugar de fijar un
# numero de columnas a mano. Al cambiar el tamano (giro de movil, ventana
# distinta) recalcula las columnas.
#
# Lo usan las tiendas de MEJORAS y de PRESTIGIO (tarjetas ShopCard) y la
# coleccion de frutas/armas (tarjetas CollectionCard).
#
# REVERTIR el diseno en rejilla de cualquier sitio: sustituir este nodo por un
# VBoxContainer en la escena y volver al listado vertical. Los modales no
# dependen de este script (solo hacen add_child/queue_free sobre el
# contenedor), asi que la vuelta atras no toca la logica de compra.
# ============================================================================

# Ancho minimo que debe poder tener una tarjeta antes de meter otra columna.
@export var min_card_width: float = 148.0
# Tope de columnas para que en unleves anchos las tarjetas no se queden
# estrechas de mas.
@export var max_columns: int = 4

func _ready() -> void:
	resized.connect(_update_columns)
	# Si vive en una ScrollContainer que aun esta oculta (pestaña sin abrir), su
	# resized no se dispara al abrirla: hay que escucharlo tambien ahi.
	var parent := get_parent()
	if parent is ScrollContainer:
		(parent as ScrollContainer).resized.connect(_update_columns)
	# call_deferred: al construirse desde codigo el ancho aun puede ser 0.
	call_deferred("_update_columns")

# Ancho realmente disponible. Si el grid todavia no tiene tamano (pestaña
# cerrada), se cae al de su ScrollContainer, que si lo tiene.
func _available_width() -> float:
	if size.x > 0.0:
		return size.x
	var parent := get_parent()
	if parent is ScrollContainer:
		return (parent as ScrollContainer).size.x
	return 0.0

func _update_columns() -> void:
	var sep: float = float(get_theme_constant("h_separation"))
	var usable: float = _available_width()
	if usable <= 0.0:
		return
	# Cuantas tarjetas caben: (n * ancho) + (n - 1) * separacion <= disponible
	var fits: int = int(floor((usable + sep) / (min_card_width + sep)))
	var target: int = clampi(fits, 1, max_columns)
	if target != columns:
		columns = target