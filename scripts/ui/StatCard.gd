class_name StatCard
extends PanelContainer
# ============================================================================
# StatCard: tarjeta "bento" de una estadística en la pantalla de Estadísticas.
#
#     ┌──────────────────┐
#     │ ⚔️  Daño         │  <- icono + nombre
#     │ 125.4            │  <- valor actual, lo que más se lee
#     └──────────────────┘
#
# El ancho lo reparte el ResponsiveGrid de la sección (3 columnas en pantallas
# anchas, menos cuando falta sitio) y la altura es fija, así que todas las
# tarjetas de una sección quedan alineadas.
#
# MODULAR: toda la construcción vive aquí. Quien llama solo hace
#     var card := StatCard.create()
#     card.setup(icon, nombre, valor, color)
# ============================================================================

# Dos bloques: nombre y valor final. El alto fijo mantiene el diseño bento.
const CARD_HEIGHT: float = 96.0
const ICON_SIZE: int = 22
const NAME_SIZE: int = 13
const VALUE_SIZE: int = 22
const TEXT_MIN_WIDTH: float = 132.0
const NAME_MIN_HEIGHT: float = 36.0
const VALUE_MIN_HEIGHT: float = 30.0

var value_label: Label

var _icon_label: Label
var _name_label: Label

# Crea la tarjeta con su jerarquia interna ya montada.
static func create() -> StatCard:
	var card := StatCard.new()
	card.custom_minimum_size = Vector2(0, CARD_HEIGHT)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	UiTheme.apply_card(card)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 3)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)

	# Icono y nombre en la misma linea: el nombre manda y empuja el icono.
	var top := HBoxContainer.new()
	top.name = "Top"
	top.add_theme_constant_override("separation", 6)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(top)

	# El icono va dentro de un Control pelado, no directamente en el HBox: asi su
	# alto minimo (66 px, por las metricas de la fuente de reserva del emoji) no se
	# propaga al contenedor y la fila no se estira al doble de lo necesario. Un
	# Control que no es Container no suma el minimo de sus hijos, y el Label se
	# dibuja al tamano que le marca su padre.
	var icon_holder := Control.new()
	icon_holder.name = "IconHolder"
	icon_holder.custom_minimum_size = Vector2(ICON_SIZE, NAME_MIN_HEIGHT)
	icon_holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(icon_holder)

	card._icon_label = Label.new()
	var icon_label: Label = card._icon_label
	icon_label.name = "IconLabel"
	icon_label.add_theme_font_size_override("font_size", ICON_SIZE)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_holder.add_child(icon_label)
	icon_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	card._name_label = Label.new()
	card._name_label.name = "NameLabel"
	card._name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	card._name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card._name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card._name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	card._name_label.clip_text = true
	card._name_label.custom_minimum_size = Vector2(TEXT_MIN_WIDTH, NAME_MIN_HEIGHT)
	card._name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card._name_label.add_theme_font_size_override("font_size", NAME_SIZE)
	card._name_label.modulate = Color(0.9, 0.95, 1.0)
	card._name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(card._name_label)

	# El valor es lo que se lee de un vistazo: va grande y con el color de la
	# estadística, para que la cifra destaque sobre el nombre.
	card.value_label = Label.new()
	card.value_label.name = "ValueLabel"
	card.value_label.custom_minimum_size = Vector2(TEXT_MIN_WIDTH, VALUE_MIN_HEIGHT)
	# Una sola línea conserva el alto real de la fuente. Con autowrap y
	# clip_text, el mínimo podía quedar por debajo de los glifos del valor.
	card.value_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	card.value_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	card.value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.value_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.value_label.add_theme_font_override("font", preload("res://assets/fonts/roboto/Roboto-Regular.ttf"))
	card.value_label.add_theme_font_size_override("font_size", VALUE_SIZE)
	card.value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(card.value_label)


	return card

# Solo nombre y valor final, también en el tooltip.
func setup(icon: String, title: String, value: String, value_color: Color) -> void:
	_icon_label.text = icon
	_icon_label.visible = not icon.is_empty()
	_name_label.text = title
	_name_label.tooltip_text = title
	value_label.text = value
	value_label.add_theme_color_override("font_color", value_color)
	tooltip_text = title + "\n" + value
