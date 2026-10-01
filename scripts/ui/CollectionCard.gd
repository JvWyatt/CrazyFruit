class_name CollectionCard
extends PanelContainer
# ============================================================================
# CollectionCard: tarjeta coleccionable de la Frutería y la Armería. Cada fruta
# o arma ocupa una posición fija en el grid (también las bloqueadas) y se ve
# como una carta: CARA con la representación visual del objeto, y REVERSO con
# sus estadísticas y descripción.
#
# TODO el contenido de compra vive DENTRO del recuadro de la carta:
#
#     ┌──────────────────┐  <- marco de la tarjeta (UiTheme.apply_card)
#     │     la fruta     │  <- FRENTE, o el REVERSO con sus datos al girarla
#     │    ────────────  │
#     │  DESBLOQUEAR $75 │  <- acción, dentro del mismo recuadro
#     └──────────────────┘
#
# REGLA DE ORO (misma que en CardFlipWidget): el botón de acción (desbloquear /
# equipar) está FUERA de la zona que gira. Al pulsar la tarjeta gira la carta;
# al pulsar el botón compra o equipa y la tarjeta ni se mueve ni se voltea.
#
# BLOQUEADAS: la tarjeta conserva su hueco en el grid pero se tapa con un velo
# oscuro y NO muestra ni la imagen ni el nombre, para que no se pueda
# identificar de qué objeto se trata hasta desbloquearlo. El velo desaparece
# en cuanto el objeto se desbloquea y la carta muestra su arte y sus datos.
#
# ANCHO: el ancho lo reparte el ResponsiveGrid; la altura es fija, y las dos
# caras miden EXACTAMENTE lo mismo (mismo padre, mismos anclajes), así que el
# flip no cambia de tamaño.
#
# MODULAR: el diseño entero de la carta vive aquí. Quien llama solo hace
#     var card := CollectionCard.create()
#     card.setup(...)
#     card.set_locked(false)
#     card.action_button.pressed.connect(...)
#
# REVERTIR: en la tienda, volver al listado con HBoxContainer como estaba. Este
# archivo se puede borrar sin tocar la logica de desbloqueo.
# ============================================================================

const FACE_HEIGHT: float = 176.0
const BUTTON_HEIGHT: float = 44.0
const BUTTON_GAP: float = 6.0
const ART_SIZE: float = 92.0
const FLIP_TIME: float = 0.16

const SCRIM_COLOR: Color = Color(0.04, 0.05, 0.09, 0.88)
# Ancho minimo de los textos con autowrap del reverso. Sin esto, un Label
# con autowrap solo mide su palabra mas larga y el panel se dispara en alto.
const TEXT_MIN_WIDTH: float = 128.0

var action_button: Button
var is_locked: bool = true

var _column: VBoxContainer
var _face: Control
var _front: Control
var _back: Control
var _scrim: ColorRect
var _badge: Label
var _art_texture: TextureRect
var _art_emoji: Label
var _name_label: Label
var _back_name_label: Label
var _stats_label: Label
var _desc_label: Label

var _flip_tween: Tween
var _flipped: bool = false

# --- Construccion -----------------------------------------------------------

static func create() -> CollectionCard:
	var card := CollectionCard.new()
	# Alto minimo del CONTENIDO (los margenes del estilo los suma el
	# PanelContainer por su cuenta): cara + separacion + boton.
	card.custom_minimum_size = Vector2(0, FACE_HEIGHT + BUTTON_GAP + BUTTON_HEIGHT)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UiTheme.apply_card(card)

	# Columna interna: lo que gira (cara) arriba, la acción abajo. Ambos dentro
	# del mismo recuadro de la tarjeta.
	card._column = VBoxContainer.new()
	card._column.name = "Column"
	card._column.add_theme_constant_override("separation", int(BUTTON_GAP))
	card.add_child(card._column)

	card._build_face()
	card._build_button()
	return card

func _build_face() -> void:
	_face = Control.new()
	_face.name = "Face"
	_face.custom_minimum_size = Vector2(0, FACE_HEIGHT)
	_face.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_face.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_face.mouse_filter = Control.MOUSE_FILTER_STOP
	_face.clip_contents = true
	_face.gui_input.connect(_on_face_gui_input)
	_column.add_child(_face)
	_face.resized.connect(_layout_faces)

	_front = PanelContainer.new()
	_front.name = "Front"
	_front.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.add_child(_front)

	var front_vbox := VBoxContainer.new()
	front_vbox.name = "FrontVBox"
	front_vbox.add_theme_constant_override("separation", 4)
	front_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_front.add_child(front_vbox)

	var art_box := CenterContainer.new()
	art_box.custom_minimum_size = Vector2(0, ART_SIZE)
	art_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	front_vbox.add_child(art_box)

	_art_texture = TextureRect.new()
	_art_texture.name = "ArtTexture"
	_art_texture.custom_minimum_size = Vector2(ART_SIZE, ART_SIZE)
	_art_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_box.add_child(_art_texture)

	_art_emoji = Label.new()
	_art_emoji.name = "ArtEmoji"
	_art_emoji.text = "🍎"
	_art_emoji.add_theme_font_size_override("font_size", 46)
	_art_emoji.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_box.add_child(_art_emoji)

	_name_label = Label.new()
	_name_label.name = "FrontName"
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.custom_minimum_size = Vector2(TEXT_MIN_WIDTH, 0)
	_name_label.add_theme_font_size_override("font_size", 13)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	front_vbox.add_child(_name_label)

	# --- Reverso: mismas medidas, solo cambian los datos ---
	_back = PanelContainer.new()
	_back.name = "Back"
	_back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_back.visible = false
	_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.add_child(_back)

	var back_vbox := VBoxContainer.new()
	back_vbox.name = "BackVBox"
	back_vbox.add_theme_constant_override("separation", 3)
	back_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back.add_child(back_vbox)

	_back_name_label = Label.new()
	_back_name_label.name = "BackName"
	_back_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_back_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_back_name_label.custom_minimum_size = Vector2(TEXT_MIN_WIDTH, 0)
	_back_name_label.add_theme_font_size_override("font_size", 13)
	_back_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_vbox.add_child(_back_name_label)

	_stats_label = Label.new()
	_stats_label.name = "Stats"
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stats_label.custom_minimum_size = Vector2(TEXT_MIN_WIDTH, 0)
	_stats_label.add_theme_font_size_override("font_size", 11)
	_stats_label.modulate = Color(0.8, 0.87, 0.93)
	_stats_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_vbox.add_child(_stats_label)

	_desc_label = Label.new()
	_desc_label.name = "Desc"
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.custom_minimum_size = Vector2(TEXT_MIN_WIDTH, 0)
	_desc_label.add_theme_font_size_override("font_size", 10)
	_desc_label.modulate = Color(0.62, 0.72, 0.8)
	_desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_vbox.add_child(_desc_label)

	# --- Capa de bloqueo: tapa la cara y esconde que objeto es ---
	_scrim = ColorRect.new()
	_scrim.name = "LockScrim"
	_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scrim.color = SCRIM_COLOR
	_scrim.visible = false
	_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.add_child(_scrim)

	_badge = Label.new()
	_badge.name = "LockBadge"
	_badge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_badge.text = "🔒\nBLOQUEADO"
	_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_badge.add_theme_font_size_override("font_size", 14)
	_badge.modulate = Color(0.62, 0.68, 0.78)
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.add_child(_badge)

func _build_button() -> void:
	action_button = Button.new()
	action_button.name = "ActionButton"
	action_button.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
	action_button.add_theme_font_size_override("font_size", 12)
	action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_column.add_child(action_button)

func _ready() -> void:
	_layout_faces()

# Frente, reverso, velo y candado comparten los mismos anclas a pantalla
# completa dentro de la cara, asi que miden EXACTAMENTE lo mismo aunque el
# reverso lleve mas texto. Aqui solo se reajusta el pivote (centro de giro) de
# cada capa cuando la cara cambia de medidas.
func _layout_faces() -> void:
	if _face == null:
		return
	var center := _face.size * 0.5
	for child in _face.get_children():
		child.pivot_offset = center

# --- Datos ------------------------------------------------------------------

# id/emoji: identificador y arte. texture: imagen opcional (frutas). Si no hay
# imagen se usa el emoji. stats/desc: contenido del reverso.
func setup(item_id: String, emoji: String, display_name: String, stats: String, desc: String, texture: Texture2D) -> void:
	if texture:
		_art_texture.texture = texture
		_art_texture.visible = true
		_art_emoji.visible = false
	else:
		_art_texture.visible = false
		_art_emoji.text = emoji
		_art_emoji.visible = true
	_name_label.text = display_name
	_back_name_label.text = display_name
	_stats_label.text = stats
	_desc_label.text = desc if not desc.is_empty() else "\n(toca para volver)"
	# Identificador util para tooltip y depuracion.
	set_meta("item_id", item_id)

# Estado bloqueado: mantiene el hueco en el grid, pero sin dejar ver el objeto.
func set_locked(locked: bool, lock_hint: String = "") -> void:
	is_locked = locked
	_scrim.visible = locked
	_badge.visible = locked
	# Sin velo: se ve el arte y el nombre; con velo: no se ve ninguno de los dos.
	_art_texture.visible = not locked and _art_texture.texture != null
	_art_emoji.visible = not locked and _art_texture.texture == null
	_name_label.visible = not locked
	if locked:
		# Al bloquear una carta que estaba volteada, vuelve a la cara.
		if _flipped:
			_flipped = false
			_back.visible = false
			_front.visible = true
			_face.scale = Vector2.ONE
			_face.pivot_offset = _face.size * 0.5
	# El requisito se explica bajo demanda (tooltip), no escrito en la carta:
	# asi el objeto sigue sin quedar identificado en el grid.
	_face.tooltip_text = ("Bloqueado. " + lock_hint) if locked else ""

# --- Flip -------------------------------------------------------------------

func _on_face_gui_input(event: InputEvent) -> void:
	if is_locked:
		return
	var pressed: bool = false
	if event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		pressed = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	if not pressed:
		return
	accept_event()
	if _flipped:
		_flip_to_front()
	else:
		_flip_to_back()

func _flip_to_back() -> void:
	_play_flip(true)

func _flip_to_front() -> void:
	_play_flip(false)

# El flip solo estrecha el EJE X a 0 y lo devuelve a 1: es el truco que usa
# CardFlipWidget, ademas de ser el giro con menos nodos de por medio (el texto
# no se reordena al girar).
func _play_flip(to_back: bool) -> void:
	if _flip_tween and _flip_tween.is_valid():
		_flip_tween.kill()
	_flipped = to_back
	_face.pivot_offset = _face.size * 0.5
	_flip_tween = create_tween()
	_flip_tween.tween_property(_face, "scale:x", 0.0, FLIP_TIME)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_flip_tween.tween_callback(_swap_face.bind(to_back))
	_flip_tween.tween_property(_face, "scale:x", 1.0, FLIP_TIME)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _swap_face(to_back: bool) -> void:
	_front.visible = not to_back
	_back.visible = to_back
	_face.pivot_offset = _face.size * 0.5
	_layout_faces()

# --- Utilidad ---------------------------------------------------------------

# Textura de una fruta SOLO si existe en el mapa de FruitVisual. Devolver null
# (y no una textura por defecto) es lo que impide que una carta bloqueada
# insinúe cual es el objeto.
static func fruit_texture(fruit_id: String) -> Texture2D:
	var path: String = str(FruitVisual.TEXTURE_PATHS.get(fruit_id, ""))
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null