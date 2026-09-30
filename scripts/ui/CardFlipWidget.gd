class_name CardFlipWidget
extends Control
# ============================================================================
# CardFlipWidget: carta seleccionable con FRENTE y REVERSO para la pantalla de
# elección de comodines (CardSelectionModal).
#
# IMPORTANTE: este widget NO contiene lógica de selección ni efectos. Solo
# PRESENTA la Dictionary de CardDatabase que ya generaba el sistema y emite
# "chosen(card_data)" para que CardSelectionModal._on_card_selected() siga
# aplicando la carta exactamente igual que antes. No se tocan get_random_cards(),
# las probabilidades ni effect_type/effect_value.
#
# MAQUETA (las dos caras son idénticas para que el giro sea simétrico):
#
#     ┌───────────────┐  <- marco del color de la RAREZ
#     │               │
#     │  la carta     │  <- ilustración, ceñida al marco (sin estirar)
#     │               │
#     └───────────────┘
#      [  ELEGIR  ]     <- DEBAJO del marco, FUERA de la carta
#
# El marco se dimensiona a partir del aspect ratio real de la ilustración, de
# modo que la caja nunca queda más alta que la imagen. El botón va fuera para
# que no se confunda con parte de la carta.
#
# IMPORTANTE (tamaño del reverso): las dos caras miden SIEMPRE lo mismo, la
# del widget entero. El reverso no se encoge ni se estira para que quepa el
# texto: la imagen del dorso va a sangre de fondo y la rareza, el título y la
# descripción se dibujan ENCIMA. Ver _build_back_art().
# ============================================================================

signal chosen(card_data: Dictionary)

const CARD_SIZE: Vector2 = Vector2(180, 300)
const COLOR_CARD_BG: Color = Color(0.09, 0.11, 0.19, 0.98)
const COLOR_TEXT_DIM: Color = Color(0.7, 0.78, 0.88)
# Grosor del marco de rareza y aire que queda entre el marco y la imagen.
const CARD_FRAME: float = 2.0
const CARD_PADDING: float = 6.0
# Separación entre el borde inferior de la carta y el botón ELEGIR.
const CARD_GAP: float = 10.0
const BUTTON_HEIGHT: float = 42.0
# Margen que deja el contenido del reverso respecto al borde de la imagen.
const BACK_TEXT_INSET: float = 6.0
# Velo que se echa sobre la imagen del dorso para que el texto se lea encima.
const COLOR_BACK_SCRIM: Color = Color(0.04, 0.05, 0.1, 0.62)
const BACK_TEXTURE: Texture2D = preload("res://assets/card/back.png")
const FRONT_ART_TEXTURE: Texture2D = preload("res://assets/card/Joker2.png")

var _data: Dictionary = {}
var _flipping: bool = false
var _showing_back: bool = false

var _front: Control = Control.new()
var _back: Control = Control.new()
var _front_panel: PanelContainer
var _back_panel: PanelContainer
var _art_container: Control
var _front_art: Control
var _back_art_rect: TextureRect
var _art_label: Label
var _back_rarity: Label
var _back_title: Label
var _back_desc: Label

func _init() -> void:
	# El alto lo marca el contenido (carta + botón), no el modal: así el marco
	# queda ceñido a la ilustración y la carta no se estira en vertical.
	custom_minimum_size = Vector2(CARD_SIZE.x, _total_height())
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_PASS
	_front.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_front.visible = true
	_back.visible = false
	add_child(_front)
	add_child(_back)

# ---------------------------------------------------------------------------
# Medidas: el marco se calcula a partir del aspect ratio real de la imagen para
# que la caja nunca sea más alta que la carta que contiene.
# ---------------------------------------------------------------------------

# Espacio que ocupa el marco por cada lado (grosor + aire interior).
func _card_inset() -> float:
	return CARD_FRAME + CARD_PADDING

# Altura sobre ancho de la ilustración (352x512 -> 1.4545 en estas cartas).
func _art_ratio() -> float:
	var tex_size: Vector2 = FRONT_ART_TEXTURE.get_size()
	if tex_size.x <= 0.0:
		return 1.45
	return tex_size.y / tex_size.x

# Tamaño del hueco donde va la ilustración, ya dentro del marco.
func _art_size() -> Vector2:
	var width: float = CARD_SIZE.x - _card_inset() * 2.0
	return Vector2(width, width * _art_ratio())

# Tamaño de la caja con marco.
func _card_box() -> Vector2:
	return Vector2(CARD_SIZE.x, _art_size().y + _card_inset() * 2.0)

# Alto total del widget: carta + hueco + botón.
func _total_height() -> float:
	return _card_box().y + CARD_GAP + BUTTON_HEIGHT

# Rellena el widget con los datos de una carta de CardDatabase.
func configure(card_data: Dictionary) -> void:
	_data = card_data
	var border: Color = card_data.get("color", Color(0.3, 0.7, 1.0))
	var rarity_text: String = "[" + str(card_data.get("rarity", "")).to_upper() + "]"
	var title_text: String = str(card_data.get("title", ""))
	var desc_text: String = str(card_data.get("desc", ""))
	var icon_text: String = str(card_data.get("icon", "🃏"))

	_build_face(true, border)
	_build_face(false, border)

	if _art_label != null:
		_art_label.text = icon_text
	_back_rarity.text = rarity_text
	_back_rarity.modulate = border
	_back_title.text = title_text
	_back_desc.text = desc_text + "\n\n⟳ Toca para elegirla"

	var image: Variant = card_data.get("image", FRONT_ART_TEXTURE)
	if image != null:
		_set_art_texture(_art_container, image)
	if _front_art != null:
		_front_art.tooltip_text = title_text + " · " + desc_text
	if _back_art_rect != null:
		_back_art_rect.texture = BACK_TEXTURE

# Gira SOLO la carta. El boton ELEGIR es hermano del marco, no hijo suyo, asi
# que se queda quieto durante la vuelta: antes se escalaba el widget entero y
# el boton se volteaba pegado a la tarjeta.
func flip() -> void:
	if _flipping:
		return
	_flipping = true
	_set_cards_filter(Control.MOUSE_FILTER_IGNORE)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_method(_set_cards_scale, 1.0, 0.0, 0.14).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		_front.visible = _showing_back
		_back.visible = not _showing_back
		_showing_back = not _showing_back
	)
	tween.tween_method(_set_cards_scale, 0.0, 1.0, 0.16).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		_flipping = false
		_set_cards_filter(Control.MOUSE_FILTER_STOP)
	)

# Solo la carta da la vuelta. El boton ELEGIR vive FUERA del marco, asi que al
# pulsarlo no le llega este evento: se limita a elegir la carta, sin girar nada.
func _on_card_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			SoundManager.play_click()
			flip()

# ---------------------------------------------------------------------------
# Construcción de caras
# ---------------------------------------------------------------------------

# Escala solo los dos marcos de carta (el widget y el boton no se tocan).
func _set_cards_scale(value: float) -> void:
	for face in [_front, _back]:
		var frame := face.get_node_or_null("Column/CardFrame") as Control
		if frame != null:
			frame.scale.x = value

# El boton ELEGIR debe quedar quieto: solo se atenua el toque de las cartas
# mientras dure la vuelta, nunca el del boton.
func _set_cards_filter(filter: int) -> void:
	for face in [_front, _back]:
		var frame := face.get_node_or_null("Column/CardFrame") as Control
		if frame != null:
			frame.mouse_filter = filter

func _build_face(is_front: bool, border: Color) -> void:
	var face := _front if is_front else _back
	if face.get_child_count() > 0:
		return
	face.mouse_filter = Control.MOUSE_FILTER_PASS

	# Columna: MARCO DE LA CARTA y, debajo y fuera, el botón ELEGIR.
	var column := VBoxContainer.new()
	column.name = "Column"
	column.mouse_filter = Control.MOUSE_FILTER_PASS
	column.add_theme_constant_override("separation", int(CARD_GAP))
	face.add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var frame := _make_card_frame(border)
	column.add_child(frame)

	if is_front:
		_build_front_art(frame)
	else:
		_build_back_art(frame)

	column.add_child(_make_choose_button())

# Marco del color de la rareza. SIZE_SHRINK_BEGIN para que NUNCA crezca: si el
# modal deja más alto, sobra espacio abajo en vez de estirar la carta.
func _make_card_frame(border: Color) -> PanelContainer:
	var frame := PanelContainer.new()
	frame.name = "CardFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_STOP
	frame.gui_input.connect(_on_card_gui_input)
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	frame.custom_minimum_size = _card_box()
	frame.clip_contents = true
	# Gira sobre su propio centro, no sobre el del widget.
	frame.pivot_offset = _card_box() * 0.5
	frame.resized.connect(func(): frame.pivot_offset = frame.size * 0.5)
	var inset := _card_inset()
	var sb := StyleBoxFlat.new()
	sb.bg_color = COLOR_CARD_BG
	sb.border_color = border
	sb.set_border_width_all(int(CARD_FRAME))
	sb.set_corner_radius_all(12)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	sb.content_margin_left = inset
	sb.content_margin_right = inset
	sb.content_margin_top = inset
	sb.content_margin_bottom = inset
	frame.add_theme_stylebox_override("panel", sb)
	return frame

# El frontal es solo la carta y el botón: sin nombre de mejora ni ningún texto
# encima. El nombre y la descripción se leen al girar la carta. Como el nombre
# ya no se pinta, se deja como tooltip del arte (solo se ve al pasar el ratón
# por encima; no añade texto a la carta).
func _build_front_art(frame: Control) -> void:
	_front_panel = frame as PanelContainer
	var art := Control.new()
	art.name = "ArtPanel"
	art.mouse_filter = Control.MOUSE_FILTER_PASS
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.custom_minimum_size = _art_size()
	art.clip_contents = true
	frame.add_child(art)
	_art_container = art
	_front_art = art

	# Marcador de posición: si una carta llega sin imagen se ve su icono.
	var art_vbox := VBoxContainer.new()
	art_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	art_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_child(art_vbox)
	art_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var art_label := Label.new()
	art_label.name = "ArtLabel"
	art_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art_label.add_theme_font_size_override("font_size", 44)
	art_label.modulate = Color(1, 1, 1, 0.9)
	art_vbox.add_child(art_label)
	_art_label = art_label
	var art_hint := Label.new()
	art_hint.text = "ILUSTRACIÓN PRÓXIMAMENTE"
	art_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art_hint.add_theme_font_size_override("font_size", 8)
	art_hint.modulate = Color(1, 1, 1, 0.45)
	art_vbox.add_child(art_hint)

# El reverso es la MISMA carta girada: no se redimensiona nunca. La imagen del
# dorso llena el hueco del marco (que ya tiene su proporción) y el texto
# (rareza, título y descripción) va ENCIMA, superpuesto.
#
# El trick que lo hace posible: el contenido cuelga de un Control simple
# ("Overlay", NO es un Container) con clip_contents = true. Al no ser Container
# no propaga su tamaño mínimo hacia el PanelContainer, así que la carta no
# crece ni se encoge por muy larga que sea la descripción; y clip_contents
# recorta el texto que no quepa en vez de deformar la carta.
#
# Ojo con los Labels con autowrap: devuelven un tamaño mínimo de (1 px de
# ancho, alto medido a 1 px), así que hay que darles a todos el ancho útil con
# custom_minimum_size. Sin eso el texto se mide a un carácter por línea y el
# marco acabaría midiendo 74x2336 px, saliéndose de la pantalla.
func _build_back_art(frame: Control) -> void:
	_back_panel = frame as PanelContainer
	var overlay := Control.new()
	overlay.name = "Overlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.clip_contents = true
	frame.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_back_art_rect = _make_art_rect()
	_back_art_rect.name = "BackArt"
	overlay.add_child(_back_art_rect)
	_back_art_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Velo oscuro para que el texto se lea sobre la ilustración.
	var scrim := ColorRect.new()
	scrim.name = "Scrim"
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scrim.color = COLOR_BACK_SCRIM
	overlay.add_child(scrim)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Bloque de texto centrado sobre la imagen. Su ancho se fija para que los
	# Labels con autowrap midan bien el salto de línea.
	var text_width: float = _art_size().x - BACK_TEXT_INSET * 2.0
	var text_box := VBoxContainer.new()
	text_box.name = "TextBox"
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	text_box.add_theme_constant_override("separation", 8)
	overlay.add_child(text_box)
	text_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	text_box.offset_left = BACK_TEXT_INSET
	text_box.offset_top = BACK_TEXT_INSET
	text_box.offset_right = -BACK_TEXT_INSET
	text_box.offset_bottom = -BACK_TEXT_INSET
	_back_rarity = _make_rarity_label(text_width)
	_back_title = _make_title_label(text_width)
	_back_desc = Label.new()
	_back_desc.name = "DescLabel"
	_back_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_back_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_back_desc.custom_minimum_size = Vector2(text_width, 0)
	_back_desc.add_theme_font_size_override("font_size", 13)
	_back_desc.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	_back_desc.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_back_desc.add_theme_constant_override("outline_size", 3)
	text_box.add_child(_back_rarity)
	text_box.add_child(_back_title)
	text_box.add_child(_back_desc)

func _make_rarity_label(min_width: float) -> Label:
	var rarity := Label.new()
	rarity.name = "RarityLabel"
	rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Mismo ancho mínimo que el resto de etiquetas: así ocupa todo el ancho de la
	# carta y el texto queda centrado, en vez de estrecharse a lo que mida la
	# palabra y quedarse pegado al borde izquierdo.
	rarity.custom_minimum_size = Vector2(min_width, 0)
	rarity.add_theme_font_size_override("font_size", 13)
	rarity.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	rarity.add_theme_constant_override("outline_size", 3)
	return rarity

func _make_title_label(min_width: float) -> Label:
	var title := Label.new()
	title.name = "TitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# CRUCIAL: un Label con autowrap devuelve tamaño mínimo de (1 px, alto
	# medido a 1 px) porque su ancho depende del que le da el contenedor. Sin
	# fijar el ancho, el texto se mide a 1 carácter por línea y el contenedor
	# crece a miles de píxeles. Le damos el ancho útil de la carta.
	title.custom_minimum_size = Vector2(min_width, 0)
	title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("outline_size", 4)
	title.add_theme_font_override("font", UiTheme.FONT_DISPLAY)
	title.add_theme_font_size_override("font_size", 20)
	return title

func _make_choose_button() -> Button:
	var choose_btn := Button.new()
	choose_btn.name = "ChooseButton"
	choose_btn.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
	choose_btn.text = "ELEGIR"
	choose_btn.add_theme_font_size_override("font_size", 15)
	choose_btn.add_theme_color_override("font_color", Color(0.25, 0.15, 0.02))
	choose_btn.add_theme_color_override("font_hover_color", Color(0.25, 0.15, 0.02))
	choose_btn.add_theme_color_override("font_pressed_color", Color(0.25, 0.15, 0.02))
	choose_btn.add_theme_stylebox_override("normal", _compact_btn_style(Color(0.98, 0.78, 0.22), Color(1, 0.95, 0.62), 4))
	choose_btn.add_theme_stylebox_override("hover", _compact_btn_style(Color(1, 0.86, 0.38), Color(1, 0.97, 0.72), 5))
	choose_btn.add_theme_stylebox_override("pressed", _compact_btn_style(Color(0.8, 0.6, 0.12), Color(0.95, 0.75, 0.25), 2))
	choose_btn.pressed.connect(func():
		SoundManager.play_victory()
		chosen.emit(_data)
	)
	return choose_btn

# ---------------------------------------------------------------------------
# Estilos
# ---------------------------------------------------------------------------

func _compact_btn_style(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb

# Crea un TextureRect de arte ya configurado.
# IMPORTANTE: expand_mode = EXPAND_IGNORE_SIZE es lo que hace que el TextureRect
# NO imponga su tamaño mínimo (352x512 en estas imágenes); sin eso el control
# crecía hasta el tamaño del PNG y empujaba el marco de la carta.
# IMPORTANTE: stretch_mode = STRETCH_KEEP_ASPECT_CENTERED muestra la imagen
# ENTERA y centrada en el hueco del marco, con su proporción intacta. Como el
# marco ya está calculado con ese mismo proportion, la imagen encaja justa.
func _make_art_rect() -> TextureRect:
	var rect := TextureRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return rect

# Muestra la imagen de la carta en su hueco, conservando el aspect ratio.
func _set_art_texture(container: Control, image: Variant) -> void:
	var tex: Texture2D = null
	if image is Texture2D:
		tex = image
	elif image is String and FileAccess.file_exists(image):
		tex = load(image) as Texture2D
	if tex == null or container == null:
		return
	# Oculta el marcador de posición (icono + hint) y muestra la imagen real.
	for child in container.get_children():
		child.visible = false
	var rect := _make_art_rect()
	rect.texture = tex
	container.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE