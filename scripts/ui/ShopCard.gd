class_name ShopCard
extends PanelContainer
# ============================================================================
# ShopCard: tarjeta compacta de TIENDA (mejoras de partida y mejoras de
# prestigio). Sustituye a la fila horizontal icono + texto + boton para que las
# tiendas se lean como un mazo de cartas en rejilla en vez de una lista.
#
# Contenido: icono grande, nombre, nivel y descripcion corta, y el boton de
# compra/abrir abajo, fuera de cualquier animacion.
#
# MODULAR: toda la construccion vive aqui. Quien llama solo hace
#     var card := ShopCard.create()
#     card.setup(...)
#     card.action_button.pressed.connect(...)
#
# REVERTIR: en la tienda, volver a construir la fila con HBoxContainer como
# estaba antes. Este archivo se puede borrar sin tocar la logica del juego.
# ============================================================================

const CARD_HEIGHT: float = 156.0
const BUTTON_HEIGHT: float = 44.0
const ICON_SIZE: int = 30
const NAME_SIZE: int = 14
const SUBTITLE_SIZE: int = 12
const DESC_SIZE: int = 11
# Ancho minimo de los textos con autowrap: sin esto el ancho minimo de la
# tarjeta seria el de su palabra mas larga y la celda del grid no bajaria.
const TEXT_MIN_WIDTH: float = 96.0

var action_button: Button
var name_label: Label
var subtitle_label: Label
var _icon_label: Label
var _desc_label: Label

# Crea la tarjeta con su jerarquia interna ya montada.
static func create(border_color: Variant = null) -> ShopCard:
	var card := ShopCard.new()
	card.custom_minimum_size = Vector2(0, CARD_HEIGHT)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.clip_contents = true
	if border_color == null:
		UiTheme.apply_card(card)
	else:
		UiTheme.apply_card(card, border_color as Color)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)

	card._icon_label = Label.new()
	var icon_label: Label = card._icon_label
	icon_label.name = "IconLabel"
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", ICON_SIZE)
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_label)

	card.name_label = Label.new()
	card.name_label.name = "NameLabel"
	card.name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	card.name_label.custom_minimum_size = Vector2(TEXT_MIN_WIDTH, NAME_SIZE + 6)
	card.name_label.add_theme_font_size_override("font_size", NAME_SIZE)
	card.name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(card.name_label)

	card.subtitle_label = Label.new()
	card.subtitle_label.name = "SubtitleLabel"
	card.subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.subtitle_label.custom_minimum_size = Vector2(TEXT_MIN_WIDTH, 0)
	card.subtitle_label.add_theme_font_size_override("font_size", SUBTITLE_SIZE)
	card.subtitle_label.modulate = Color(1, 0.95, 0.7)
	card.subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(card.subtitle_label)

	card._desc_label = Label.new()
	var desc_label: Label = card._desc_label
	desc_label.name = "DescLabel"
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(TEXT_MIN_WIDTH, 0)
	desc_label.add_theme_font_size_override("font_size", DESC_SIZE)
	desc_label.modulate = Color(0.78, 0.84, 0.9)
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_label.clip_text = true
	vbox.add_child(desc_label)

	card.action_button = Button.new()
	card.action_button.name = "ActionButton"
	card.action_button.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
	card.action_button.add_theme_font_size_override("font_size", 13)
	vbox.add_child(card.action_button)

	return card

# Rellena el contenido. subtitle puede ir vacio si la mejora no tiene niveles.
func setup(icon: String, title: String, subtitle: String, desc: String, action_text: String, action_enabled: bool) -> void:
	_icon_label.text = icon
	name_label.text = title
	subtitle_label.text = subtitle
	subtitle_label.visible = not subtitle.is_empty()
	_desc_label.text = desc
	action_button.text = action_text
	action_button.disabled = not action_enabled