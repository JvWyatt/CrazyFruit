extends Control
# ============================================================================
# KnifeShopModal: tienda de armas PERMANENTE (usa el dinero total histórico,
# no el de la partida actual). NOTA: actualmente ningún botón del menú la
# abre; la tienda de armas que se usa realmente durante la partida es la
# pestaña "Armas" de RunUpgradeModal.gd.
# ============================================================================

signal modal_closed

@onready var items_container: VBoxContainer = $Panel/VBox/ScrollContainer/ItemsVBox
@onready var close_button: Button = $Panel/VBox/HeaderHBox/CloseButton
@onready var total_money_label: Label = $Panel/VBox/HeaderHBox/TotalMoneyLabel

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)

func open_modal() -> void:
	visible = true
	UiTheme.pop_in($Panel)
	_refresh_ui()

func _refresh_ui() -> void:
	var total_earned: float = SaveManager.get_wallet_balance()
	total_money_label.text = "💰 Ganancias Totales: $" + _format_number(total_earned)

	for child in items_container.get_children():
		child.queue_free()

	var knife_keys = StatsManager.knives_db.keys()
	var equipped_id = SaveManager.get_equipped_knife()

	for k_id in knife_keys:
		var k_data = StatsManager.knives_db[k_id]
		var is_unlocked = SaveManager.is_knife_unlocked(k_id)
		var is_equipped = (k_id == equipped_id)
		var price: int = StatsManager.get_weapon_price(int(k_data["price"]))

		var panel := PanelContainer.new()
		UiTheme.apply_card(panel, Color(0.3, 0.8, 1.0) if is_equipped else UiTheme.COLOR_BORDER)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)

		var icon_lbl := Label.new()
		icon_lbl.text = str(k_data["icon"])
		icon_lbl.add_theme_font_size_override("font_size", 34)

		var text_vbox := VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl := Label.new()
		name_lbl.text = str(k_data["name"]) + (" [EN USO]" if is_equipped else "")
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.modulate = Color(1.0, 0.88, 0.3) if is_equipped else Color(1.0, 1.0, 1.0)

		var stats_lbl := Label.new()
		stats_lbl.text = "⚔️ Daño: " + str(int(k_data["damage"])) + "  |  ⚡ Gasto: " + str(int(k_data["energy_cost"])) + " En."
		stats_lbl.add_theme_font_size_override("font_size", 14)
		stats_lbl.modulate = Color(0.4, 0.9, 0.5)

		var desc_lbl := Label.new()
		desc_lbl.text = str(k_data["description"])
		desc_lbl.add_theme_font_size_override("font_size", 13)
		desc_lbl.modulate = Color(0.75, 0.8, 0.9)

		text_vbox.add_child(name_lbl)
		text_vbox.add_child(stats_lbl)
		text_vbox.add_child(desc_lbl)

		var action_btn := Button.new()
		action_btn.custom_minimum_size = Vector2(130, 48)

		var captured_id = k_id
		if is_equipped:
			action_btn.text = "EN USO"
			action_btn.disabled = true
		elif is_unlocked:
			action_btn.text = "EQUIPAR"
			action_btn.pressed.connect(func():
				SaveManager.set_equipped_knife(captured_id)
				SoundManager.play_click()
				_refresh_ui()
			)
		else:
			action_btn.text = "DESBLOQUEAR\n$" + _format_number(float(price))
			var can_unlock: bool = total_earned >= price
			action_btn.disabled = not can_unlock
			action_btn.pressed.connect(func():
				if SaveManager.spend_wallet_balance(price):
					SaveManager.unlock_knife(captured_id)
					SaveManager.set_equipped_knife(captured_id)
					SoundManager.play_victory()
					_refresh_ui()
			)

		hbox.add_child(icon_lbl)
		hbox.add_child(text_vbox)
		hbox.add_child(action_btn)

		panel.add_child(hbox)
		items_container.add_child(panel)

func _on_close_pressed() -> void:
	SoundManager.play_click()
	visible = false
	emit_signal("modal_closed")

func _format_number(val: float) -> String:
	var int_val: int = int(round(val))
	var str_val: String = str(int_val)
	var formatted: String = ""
	var count: int = 0
	for i in range(str_val.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted = "," + formatted
		formatted = str_val[i] + formatted
		count += 1
	return formatted
