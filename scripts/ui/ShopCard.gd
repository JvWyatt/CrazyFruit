class_name ShopCard
extends PanelContainer
# ============================================================================
# ShopCard: tarjeta compacta de TIENDA (mejoras de partida y mejoras de
# prestigio). Sustituye a la fila horizontal icono + texto + boton para que las
# tiendas se lean como un mazo de cartas en rejilla en vez de una lista.
#
# Contenido: icono grande, nombre, nivel, valor final e incremento, y el boton de
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

const CARD_HEIGHT: float = 184.0
const BUTTON_HEIGHT: float = 44.0
const ICON_SIZE: int = 24
# Alto reservado al icono (el glifo a ICON_SIZE mide ~26 px; va holgado para que
# no se recorte) en lugar de dejar que lo imponga la fuente de reserva del emoji.
const ICON_HEIGHT: float = 28.0
const NAME_SIZE: int = 14
const SUBTITLE_SIZE: int = 12
const DESC_SIZE: int = 11
# Ancho minimo de los textos con autowrap: sin esto el ancho minimo de la
# tarjeta seria el de su palabra mas larga y la celda del grid no bajaria.
const TEXT_MIN_WIDTH: float = 96.0

var action_button: Button
var name_label: Label
var subtitle_label: Label
var current_stat_label: Label
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
	# Márgenes compactos propios: no modificar el estilo compartido del tema.
	var compact_style: StyleBox = card.get_theme_stylebox("panel").duplicate()
	compact_style.content_margin_top = 6.0
	compact_style.content_margin_bottom = 6.0
	compact_style.content_margin_left = 12.0
	compact_style.content_margin_right = 12.0
	card.add_theme_stylebox_override("panel", compact_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)

	# El icono va en un Control pelado en vez de directo en el VBox: asi el alto
	# minimo de la etiqueta (que sale de las metricas de la fuente, no del glifo)
	# no se propaga al contenedor y la tarjeta no se estira. El alto lo marca
	# ICON_HEIGHT; el Label se dibuja al tamano que le da su padre.
	var icon_holder := Control.new()
	icon_holder.name = "IconHolder"
	icon_holder.custom_minimum_size = Vector2(0, ICON_HEIGHT)
	icon_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_holder)

	card._icon_label = Label.new()
	var icon_label: Label = card._icon_label
	icon_label.name = "IconLabel"
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", ICON_SIZE)
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_holder.add_child(icon_label)
	icon_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	card.name_label = Label.new()
	card.name_label.name = "NameLabel"
	card.name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	card.name_label.clip_text = true
	card.name_label.custom_minimum_size = Vector2(TEXT_MIN_WIDTH, 34)
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

	card.current_stat_label = Label.new()
	card.current_stat_label.name = "CurrentStatLabel"
	card.current_stat_label.visible = false
	card.current_stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.current_stat_label.custom_minimum_size = Vector2(TEXT_MIN_WIDTH, 20)
	card.current_stat_label.add_theme_font_override("font", preload("res://assets/fonts/roboto/Roboto-Regular.ttf"))
	card.current_stat_label.add_theme_font_size_override("font_size", 14)
	card.current_stat_label.add_theme_color_override("font_color", Color.WHITE)
	card.current_stat_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(card.current_stat_label)

	card._desc_label = Label.new()
	var desc_label: Label = card._desc_label
	desc_label.name = "DescLabel"
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(TEXT_MIN_WIDTH, 18)
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

# Las claves de prestigio leen exclusivamente estadísticas permanentes.
# Solo las claves del mercado consultan los valores finales de la run.
func update_current_stat(stat_key: String) -> void:
	var text: String = ""
	match stat_key:
		"experience":
			text = "Daño: " + UiTheme.format_stat(StatsManager.get_permanent_stat(stat_key))
		"expert_hand":
			text = "Resistencia: " + UiTheme.format_stat(StatsManager.get_permanent_stat(stat_key))
		"good_fortune":
			text = "Jackpot: " + UiTheme.format_stat(StatsManager.get_permanent_stat(stat_key) * 100.0) + "%"
		"good_provider":
			text = "Dinero: x" + UiTheme.format_stat(StatsManager.get_permanent_stat(stat_key))
		"launch_speed":
			text = "Velocidad: " + UiTheme.format_stat(StatsManager.get_permanent_stat(stat_key)) + " frutas/s"
		"damage":
			text = "Daño: " + UiTheme.format_stat(StatsManager.get_final_damage())
		"energy_max":
			text = "Resistencia: " + UiTheme.format_stat(StatsManager.get_final_max_energy())
		"luck":
			text = "Jackpot: " + UiTheme.format_stat(StatsManager.get_final_jackpot_bonus() * 100.0) + "%"
		"money":
			text = "Dinero: x" + UiTheme.format_stat(StatsManager.get_final_money_multiplier())
		"launch_rate":
			text = "Velocidad: " + UiTheme.format_stat(StatsManager.get_final_launch_rate()) + " frutas/s"
	current_stat_label.text = text
	current_stat_label.visible = not text.is_empty()
