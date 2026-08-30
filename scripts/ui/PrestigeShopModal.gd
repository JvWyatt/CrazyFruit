extends Control
# ============================================================================
# PrestigeShopModal: tienda de mejoras PERMANENTES compradas con reputación
# (prestige_points en SaveManager). Los precios/efectos de cada mejora están
# en StatsManager.prestige_definitions.
# ============================================================================

signal modal_closed

@onready var prestige_label: Label = $Panel/VBox/HeaderHBox/PrestigeLabel
@onready var close_button: Button = $Panel/VBox/HeaderHBox/CloseButton
@onready var items_container: VBoxContainer = $Panel/VBox/ScrollContainer/ItemsVBox

var prestige_keys: Array[String] = ["experience", "expert_hand", "good_provider", "good_fortune", "launch_speed"]

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	SaveManager.prestige_changed.connect(func(_p): _refresh_ui())
	StatsManager.stats_updated.connect(_refresh_ui)

func open_modal() -> void:
	visible = true
	UiTheme.pop_in($Panel)
	_refresh_ui()

func _refresh_ui() -> void:
	prestige_label.text = "⭐ " + str(SaveManager.get_prestige_points()) + " Rep."

	for child in items_container.get_children():
		child.queue_free()

	for key in prestige_keys:
		var def: Dictionary = StatsManager.prestige_definitions[key]
		var level: int = SaveManager.get_prestige_level(key)
		var cost: int = StatsManager.get_prestige_upgrade_cost(key)
		var can_buy: bool = SaveManager.get_prestige_points() >= cost

		var panel := PanelContainer.new()
		UiTheme.apply_card(panel)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)

		var icon_lbl := Label.new()
		icon_lbl.text = str(def["icon"])
		icon_lbl.add_theme_font_size_override("font_size", 32)

		var text_vbox := VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl := Label.new()
		name_lbl.text = str(def["name"]) + " (x" + str(level) + ")"
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.modulate = Color(1.0, 0.88, 0.3)

		var desc_lbl := Label.new()
		desc_lbl.text = str(def["desc"])
		desc_lbl.add_theme_font_size_override("font_size", 14)
		desc_lbl.modulate = Color(0.85, 0.9, 0.95)

		text_vbox.add_child(name_lbl)
		text_vbox.add_child(desc_lbl)

		var buy_btn := Button.new()
		buy_btn.custom_minimum_size = Vector2(130, 48)
		buy_btn.text = str(cost) + " ⭐"
		buy_btn.add_theme_font_size_override("font_size", 17)
		buy_btn.disabled = not can_buy

		var captured_key = key
		buy_btn.pressed.connect(func():
			if StatsManager.buy_prestige_upgrade(captured_key):
				SoundManager.play_victory()
				_refresh_ui()
		)

		hbox.add_child(icon_lbl)
		hbox.add_child(text_vbox)
		hbox.add_child(buy_btn)

		panel.add_child(hbox)
		items_container.add_child(panel)

func _on_close_pressed() -> void:
	SoundManager.play_click()
	visible = false
	emit_signal("modal_closed")
