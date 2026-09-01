extends Control
# ============================================================================
# ProgressModal: muestra estadísticas PERMANENTES de todo lo jugado hasta
# ahora (reputación, ganancias totales, frutas/armas descubiertas alguna vez,
# comodines descubiertos). Todo viene de SaveManager.save_data, solo lectura.
# ============================================================================

@onready var close_button: Button = $Panel/VBox/HeaderHBox/CloseButton
@onready var progress_container: VBoxContainer = $Panel/VBox/ScrollContainer/ProgressVBox

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)

func open_modal() -> void:
	visible = true
	UiTheme.pop_in($Panel)
	_refresh_ui()

func _refresh_ui() -> void:
	for child in progress_container.get_children():
		child.queue_free()

	_add_section("🏆 PROGRESO")
	_add_row("Reputación acumulada", str(int(SaveManager.save_data.get("total_reputation_earned", 0))))
	_add_row("Días completados", str(int(SaveManager.save_data.get("best_clients_in_day", 0))))
	_add_row("Negocios en quiebra", str(int(SaveManager.save_data.get("days_started", 0))))

	_add_section("🍓 FRUTAS DISPONIBLES")
	var unlocked_fruits: Array = SaveManager.get_unlocked_fruits()
	_add_row("Frutas desbloqueadas", str(unlocked_fruits.size()) + " / " + str(FruitDatabase.FRUITS.size()))

	_add_section("🃏 COMODINES DESCUBIERTOS")
	var discovered_cards: Array = SaveManager.get_discovered_cards()
	var total_by_rarity: Dictionary = {}
	for card in CardDatabase.ALL_CARDS:
		var rarity: String = str(card["rarity"])
		total_by_rarity[rarity] = int(total_by_rarity.get(rarity, 0)) + 1
	var discovered_by_rarity: Dictionary = {}
	for card_id in discovered_cards:
		for card in CardDatabase.ALL_CARDS:
			if str(card["id"]) == str(card_id):
				var rarity: String = str(card["rarity"])
				discovered_by_rarity[rarity] = int(discovered_by_rarity.get(rarity, 0)) + 1
				break
	var rarity_labels: Dictionary = {
		"Común": "Comunes",
		"Rara": "Raros",
		"Épica": "Épicos",
		"Legendaria": "Legendarios",
		"Mítico": "Míticos",
	}
	for rarity in CardDatabase.RARITIES:
		_add_row(str(rarity_labels.get(rarity, rarity)), str(discovered_by_rarity.get(rarity, 0)) + " / " + str(total_by_rarity.get(rarity, 0)))

func _add_section(title: String) -> void:
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 18)
	label.modulate = Color(1.0, 0.85, 0.3)
	progress_container.add_child(label)

func _add_row(label_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 16)
	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 16)
	value.modulate = Color(0.7, 0.95, 0.75)
	row.add_child(label)
	row.add_child(value)
	progress_container.add_child(row)

func _on_close_pressed() -> void:
	SoundManager.play_click()
	visible = false
