extends Control
# ============================================================================
# CardsModal: galería de comodines (descubiertos históricamente, o los activos
# en la partida actual). Solo lectura, no modifica balance.
#
# PRESENTACION: rejilla de miniaturas reales —el mismo CardFlipWidget que se usa
# en la pantalla de elección, en modo THUMBNAIL— en lugar del listado de texto.
# Al tocar una miniatura se abre la carta en grande (modo DETAIL) y desde ahí se
# puede girar con el MISMO efecto flip para leer el reverso y su descripción.
# ============================================================================

const THUMBNAIL_WIDTH: float = 104.0
const GRID_SEPARATION: int = 12
# Techo de la carta grande. Es solo un tope: el ancho real sale de lo que cabe en
# alto dentro del hueco del detalle, asi que en pantallas grandes la carta crece
# hasta llenar el panel sin dejar un vacio enorme debajo.
const DETAIL_MAX_WIDTH: float = 420.0
const DETAIL_STEP: float = 10.0

@onready var title_label: Label = $Panel/VBox/HeaderHBox/TitleLabel
@onready var close_button: Button = $Panel/VBox/HeaderHBox/CloseButton
@onready var rarity_legend: RichTextLabel = $Panel/VBox/RarityLegend
@onready var empty_label: Label = $Panel/VBox/EmptyLabel
@onready var cards_grid: ResponsiveGrid = $Panel/VBox/ScrollContainer/CardsGrid
@onready var detail_layer: Control = $DetailLayer
@onready var detail_panel: PanelContainer = $DetailLayer/DetailPanel
@onready var detail_title: Label = $DetailLayer/DetailPanel/DetailVBox/DetailTitle
@onready var detail_host: CenterContainer = $DetailLayer/DetailPanel/DetailVBox/CardHost
@onready var detail_back_button: Button = $DetailLayer/DetailPanel/DetailVBox/DetailBackButton

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	detail_back_button.pressed.connect(_close_detail)
	$DetailLayer/DetailDimmer.gui_input.connect(_on_detail_dimmer_input)
	# La rejilla de miniaturas usa el mismo ritmo que el resto de grids.
	cards_grid.h_separation = GRID_SEPARATION
	cards_grid.v_separation = GRID_SEPARATION

func open_discovered_cards() -> void:
	title_label.text = "🃏 Comodines descubiertos"
	visible = true
	UiTheme.pop_in($Panel)
	_refresh_cards(SaveManager.get_discovered_cards())

func open_active_cards() -> void:
	title_label.text = "ⓘ Comodines activos"
	visible = true
	UiTheme.pop_in($Panel)
	var active_ids: Array = []
	for card in StatsManager.active_cards:
		active_ids.append(card.get("id", ""))
	_refresh_cards(active_ids)

func _refresh_cards(card_ids: Array) -> void:
	for child in cards_grid.get_children():
		child.queue_free()

	var found_cards: Array[Dictionary] = []
	for card_id in card_ids:
		for card in CardDatabase.ALL_CARDS:
			if str(card["id"]) == str(card_id):
				found_cards.append(card)
				break

	empty_label.visible = found_cards.is_empty()
	rarity_legend.visible = not found_cards.is_empty()
	if found_cards.is_empty():
		rarity_legend.text = ""
		return

	# Ordenadas por rareza (de la mas comun a la mas rara) para que la rejilla
	# se lea por franjas de color sin necesidad de encabezados intermedios.
	found_cards.sort_custom(_sort_by_rarity)

	for card in found_cards:
		cards_grid.add_child(_make_thumbnail(card))

	_update_rarity_legend(found_cards)

# Miniatura de la rejilla: el MISMO componente de carta de la pantalla de
# elección, en modo THUMBNAIL (sin botón: al tocarla pide abrirla en grande).
func _make_thumbnail(card_data: Dictionary) -> CardFlipWidget:
	var thumb := CardFlipWidget.new()
	thumb.set_mode(CardFlipWidget.Presentation.THUMBNAIL, THUMBNAIL_WIDTH)
	thumb.configure(card_data)
	thumb.previewed.connect(_on_thumbnail_pressed)
	return thumb

# --- Vista de detalle -------------------------------------------------------

func _on_thumbnail_pressed(card_data: Dictionary) -> void:
	_open_detail(card_data)

# Abre la carta grande. El tamaño se calcula con CardFlipWidget.height_for() para
# que la carta entre siempre en el hueco, sin recortarse ni dejarse sitio de mas.
#
# La capa tiene que estar visible ANTES de medir: un Container oculto todavia no
# ha repartido su tamano a los hijos, asi que detail_host.size valdria 0 y la carta
# se quedaria en el ancho de reserva en vez de aprovechar el hueco.
func _open_detail(card_data: Dictionary) -> void:
	for child in detail_host.get_children():
		child.queue_free()
	detail_title.text = str(card_data.get("title", "Comodín"))
	detail_layer.visible = true
	await get_tree().process_frame
	if not is_instance_valid(detail_host):
		return
	var big := CardFlipWidget.new()
	big.set_mode(CardFlipWidget.Presentation.DETAIL, _detail_width())
	big.configure(card_data)
	detail_host.add_child(big)
	UiTheme.pop_in(detail_panel)

func _close_detail() -> void:
	if not detail_layer.visible:
		return
	detail_layer.visible = false
	for child in detail_host.get_children():
		child.queue_free()

# Ancho maximo de la carta grande que cabe en el hueco del detalle.
func _detail_width() -> float:
	var available: Vector2 = detail_host.size
	if available.y <= 0.0:
		return 280.0
	var width: float = THUMBNAIL_WIDTH
	while width < DETAIL_MAX_WIDTH and CardFlipWidget.height_for(width + DETAIL_STEP) <= available.y:
		width += DETAIL_STEP
	if available.x > 0.0:
		width = minf(width, maxf(available.x - 8.0, THUMBNAIL_WIDTH))
	return width

# Tocar fuera del panel de detalle es lo mismo que pulsar VOLVER.
func _on_detail_dimmer_input(event: InputEvent) -> void:
	var pressed: bool = false
	if event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		pressed = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	if pressed:
		accept_event()
		_close_detail()

# --- Leyenda de rarezas -----------------------------------------------------

# Resumen "Común 12 · Rara 3 · Épica 1": sustituye a los encabezados de rareza
# que tenía el listado de texto, ahora que la rejilla no separa secciones.
func _update_rarity_legend(found_cards: Array[Dictionary]) -> void:
	var parts: PackedStringArray = []
	for rarity in CardDatabase.RARITIES:
		var count: int = 0
		for card in found_cards:
			if str(card["rarity"]) == rarity:
				count += 1
		if count <= 0:
			continue
		var hex: String = CardDatabase.rarity_color(rarity).to_html(false)
		parts.append("[color=#" + hex + "]" + rarity + " " + str(count) + "[/color]")
	rarity_legend.text = " · ".join(parts)

func _sort_by_rarity(a: Dictionary, b: Dictionary) -> bool:
	var ia: int = CardDatabase.RARITIES.find(str(a.get("rarity", "")))
	var ib: int = CardDatabase.RARITIES.find(str(b.get("rarity", "")))
	return ia < ib

# --- Cierre -----------------------------------------------------------------

func _on_close_pressed() -> void:
	SoundManager.play_click()
	_close_detail()
	visible = false