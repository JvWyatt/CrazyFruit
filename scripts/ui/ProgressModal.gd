extends Control
# ============================================================================
# ProgressModal: muestra el progreso permanente del jugador: días completados,
# negocios en quiebra y comodines descubiertos. Todo viene de
# SaveManager.save_data, solo lectura.
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

	_add_row("Días completados", str(int(SaveManager.save_data.get("best_clients_in_day", 0))))
	_add_row("Negocios en quiebra", str(int(SaveManager.save_data.get("days_started", 0))))
	_add_row("Comodines descubiertos", str(SaveManager.get_discovered_cards().size()) + " / " + str(CardDatabase.ALL_CARDS.size()))

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
