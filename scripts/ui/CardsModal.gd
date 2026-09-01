extends Control
# ============================================================================
# CardsModal: muestra la galería de comodines (descubiertos históricamente,
# o los activos en la partida actual). Solo lectura, no modifica balance.
# ============================================================================

@onready var title_label: Label = $Panel/VBox/HeaderHBox/TitleLabel
@onready var close_button: Button = $Panel/VBox/HeaderHBox/CloseButton
@onready var cards_container: VBoxContainer = $Panel/VBox/ScrollContainer/CardsVBox

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)

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
	for child in cards_container.get_children():
		child.queue_free()

	var found_cards: Array[Dictionary] = []
	for card_id in card_ids:
		for card in CardDatabase.ALL_CARDS:
			if str(card["id"]) == str(card_id):
				found_cards.append(card)
				break

	if found_cards.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Todavía no hay comodines para mostrar."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 17)
		cards_container.add_child(empty_label)
		return

	for rarity in CardDatabase.RARITIES:
		var rarity_cards: Array[Dictionary] = []
		for card in found_cards:
			if str(card["rarity"]) == rarity:
				rarity_cards.append(card)
		if rarity_cards.is_empty():
			continue
		var rarity_label := Label.new()
		rarity_label.text = rarity
		rarity_label.add_theme_font_size_override("font_size", 18)
		rarity_label.modulate = CardDatabase.rarity_color(rarity)
		cards_container.add_child(rarity_label)
		for card in rarity_cards:
			var card_label := Label.new()
			card_label.text = str(card["title"]) + " [" + rarity + "]\n" + str(card["desc"])
			card_label.add_theme_font_size_override("font_size", 15)
			card_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			cards_container.add_child(card_label)

func _on_close_pressed() -> void:
	SoundManager.play_click()
	visible = false
