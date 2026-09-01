extends Control
# ============================================================================
# RunUpgradeModal: el "mercado" que se abre entre pedidos, con 3 pestañas:
#   - Mejoras:   sube daño/energía/suerte/dinero con el dinero de la partida
#   - Frutería:  desbloquea frutas nuevas para esta partida
#   - Armas:     desbloquea y equipa armas nuevas para esta partida
# TODO lo comprado aquí usa GameManager.run_money y se pierde si el negocio
# quiebra (ver GameManager.start_new_run que reinicia run_unlocked_fruits,
# run_unlocked_knives y StatsManager.run_upgrade_levels).
# ============================================================================

signal modal_closed
signal start_next_order_requested
signal open_stats_requested

@onready var title_label: Label = $Panel/VBox/HeaderHBox/TitleLabel
@onready var money_label: Label = $Panel/VBox/HeaderHBox/MoneyLabel
@onready var close_button: Button = $Panel/VBox/HeaderHBox/CloseButton
@onready var items_container: VBoxContainer = $Panel/VBox/TabContainer/Mejoras/ItemsVBox
@onready var fruit_items_container: VBoxContainer = $Panel/VBox/TabContainer/Frutería/ItemsVBox
@onready var weapon_items_container: VBoxContainer = $Panel/VBox/TabContainer/Armas/ItemsVBox
@onready var stats_button: Button = $Panel/VBox/BottomHBox/StatsButton
@onready var continue_button: Button = $Panel/VBox/BottomHBox/ContinueButton

var upgrade_keys: Array[String] = ["damage", "energy_max", "luck", "money", "launch_rate"]
var fruit_prices: Dictionary = {
	# Progresión rebalanceada (curva MÁS empinada que antes): cada fruta cuesta
	# ~2x la anterior. Las primeras se siguen comprando en los primeros días,
	# pero las de gama media/alta requieren correr mucho más profundo en el
	# negocio, para que no puedas comprar casi todo en las primeras runs.
	# La Frutería está bloqueada en cadena: no puedes comprar una fruta sin
	# haber comprado la anterior (ver _get_prev_fruit_id).
	# Todos los precios se multiplicaron x2 en el rebalanceo general.
	"banana": 240,
	"peach": 520,
	"cherry": 1100,
	"orange": 2200,
	"apple": 4400,
	"pear": 8400,
	"kiwi": 16000,
	"mango": 30000,
	"lemon": 60000,
	"watermelon": 120000,
	"melon": 240000,
	"pineapple": 480000,
	"papaya": 960000,
	"coconut": 1920000,
	"avocado": 3800000,
	"dragon_fruit": 7600000,
	"guava": 15000000,
	"quince": 30000000,
	"pumpkin": 60000000
}

# Cached row refs so purchases can update in place instead of rebuilding the whole shop
var _upgrade_rows: Dictionary = {} # key -> {name_lbl, buy_btn}
var _fruit_rows: Dictionary = {} # fruit_id -> {buy_btn, price}

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	stats_button.pressed.connect(_on_stats_pressed)

func open_modal(order_completed_num: int = 0) -> void:
	visible = true
	UiTheme.pop_in($Panel)
	if order_completed_num > 0:
		title_label.text = "🛒 MERCADO — FIN DEL DÍA #" + str(order_completed_num)
		continue_button.text = "⚔️ INICIAR SIGUIENTE DÍA"
	else:
		title_label.text = "🛒 Mercado de Mejoras"
		continue_button.text = "⚔️ CONTINUAR NEGOCIO"
	_rebuild_ui()

func _refresh_ui() -> void:
	# Only update money label without rebuilding UI
	money_label.text = "💰 $" + _format_number(GameManager.run_money)

# Full UI rebuild (expensive, only call on open)
func _rebuild_ui() -> void:
	money_label.text = "💰 $" + _format_number(GameManager.run_money)

	for child in items_container.get_children():
		child.queue_free()
	_upgrade_rows.clear()

	for key in upgrade_keys:
		var def: Dictionary = StatsManager.run_upgrade_definitions[key]
		var level: int = StatsManager.run_upgrade_levels[key]
		var cost: int = StatsManager.get_run_upgrade_cost(key)
		var can_buy: bool = GameManager.run_money >= cost

		var panel := PanelContainer.new()
		UiTheme.apply_card(panel)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)

		var icon_lbl := Label.new()
		icon_lbl.text = str(def["icon"])
		icon_lbl.add_theme_font_size_override("font_size", 28)

		var text_vbox := VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl := Label.new()
		name_lbl.text = str(def["name"]) + " (x" + str(level) + ")"
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.modulate = Color(1.0, 0.95, 0.7)

		var desc_lbl := Label.new()
		desc_lbl.text = str(def["desc"])
		desc_lbl.add_theme_font_size_override("font_size", 14)
		desc_lbl.modulate = Color(0.8, 0.85, 0.9)

		text_vbox.add_child(name_lbl)
		text_vbox.add_child(desc_lbl)

		var buy_btn := Button.new()
		buy_btn.custom_minimum_size = Vector2(120, 48)
		buy_btn.text = "$" + _format_number(float(cost))
		buy_btn.add_theme_font_size_override("font_size", 16)
		buy_btn.disabled = not can_buy

		var up_key = key
		buy_btn.pressed.connect(func():
			_on_buy_upgrade(up_key)
		)

		hbox.add_child(icon_lbl)
		hbox.add_child(text_vbox)
		hbox.add_child(buy_btn)

		panel.add_child(hbox)
		items_container.add_child(panel)

		_upgrade_rows[key] = {"name_lbl": name_lbl, "buy_btn": buy_btn, "def": def}

	_rebuild_fruit_shop()
	_rebuild_weapon_shop()

# Update a single upgrade row (level text + cost) after purchase, no rebuild
func _update_upgrade_row(key: String) -> void:
	if not _upgrade_rows.has(key):
		return
	var row: Dictionary = _upgrade_rows[key]
	var level: int = StatsManager.run_upgrade_levels[key]
	var cost: int = StatsManager.get_run_upgrade_cost(key)
	row["name_lbl"].text = str(row["def"]["name"]) + " (x" + str(level) + ")"
	row["buy_btn"].text = "$" + _format_number(float(cost))

# Fruta anterior en la cadena de desbloqueo ("" si es la primera). Regla de
# la Frutería: no se puede comprar una fruta sin haber comprado la anterior.
func _get_prev_fruit_id(fruit_id: String) -> String:
	var ids: Array[String] = FruitDatabase.get_sorted_fruit_ids()
	var idx: int = ids.find(fruit_id)
	if idx > 0:
		return ids[idx - 1]
	return ""

# Arma anterior en la cadena de desbloqueo ("" si es la primera). Regla de la
# Armería: no se puede desbloquear un arma sin haber desbloqueado la anterior.
func _get_prev_knife_id(knife_id: String) -> String:
	var ids: Array = StatsManager.knives_db.keys()
	var idx: int = ids.find(knife_id)
	if idx > 0:
		return str(ids[idx - 1])
	return ""

# Refresh disabled state of all buy buttons based on current money, no node creation
func _refresh_affordability() -> void:
	var money: float = GameManager.run_money
	for key in _upgrade_rows.keys():
		var row: Dictionary = _upgrade_rows[key]
		var cost: int = StatsManager.get_run_upgrade_cost(key)
		row["buy_btn"].disabled = money < cost
	for fruit_id in _fruit_rows.keys():
		_sync_fruit_row(str(fruit_id))
	_rebuild_weapon_shop()

# Sincroniza el texto/estado del botón de una fruta de la Frutería teniendo en
# cuenta DOS cosas: dinero suficiente Y que esté desbloqueada la fruta anterior
# (regla de cadena).
func _sync_fruit_row(fruit_id: String) -> void:
	if not _fruit_rows.has(fruit_id):
		return
	var row: Dictionary = _fruit_rows[fruit_id]
	var buy_btn: Button = row["buy_btn"]
	if GameManager.is_fruit_unlocked_this_run(fruit_id):
		buy_btn.text = "DISPONIBLE"
		buy_btn.disabled = true
		return
	var prev_id: String = _get_prev_fruit_id(fruit_id)
	var chain_ok: bool = prev_id == "" or GameManager.is_fruit_unlocked_this_run(prev_id)
	if not chain_ok:
		buy_btn.text = "🔒 BLOQUEADO"
		buy_btn.disabled = true
		return
	buy_btn.text = "DESBLOQUEAR\n$" + _format_number(float(row["price"]))
	buy_btn.disabled = GameManager.run_money < int(row["price"])

func _rebuild_fruit_shop() -> void:
	for child in fruit_items_container.get_children():
		child.queue_free()
	_fruit_rows.clear()

	var fruit_ids: Array[String] = FruitDatabase.get_sorted_fruit_ids()
	for fruit_id in fruit_ids:
		var fruit_data: Dictionary = FruitDatabase.get_fruit_data(fruit_id)
		var price: int = StatsManager.get_fruit_price(int(fruit_prices.get(fruit_id, 0)))
		var prev_id: String = _get_prev_fruit_id(fruit_id)
		var chain_ok: bool = prev_id == "" or GameManager.is_fruit_unlocked_this_run(prev_id)
		var panel := PanelContainer.new()
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)

		var icon_lbl := Label.new()
		icon_lbl.text = str(fruit_data["emoji"])
		icon_lbl.add_theme_font_size_override("font_size", 30)
		var name_lbl := Label.new()
		name_lbl.text = str(fruit_data["name"])
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_size_override("font_size", 18)
		var stats_lbl := Label.new()
		stats_lbl.text = "Vida: " + str(int(fruit_data["max_hp"])) + "  |  Ganancias: $" + str(fruit_data["min_reward"]) + " - $" + str(fruit_data["max_reward"])
		if not chain_ok:
			var prev_data: Dictionary = FruitDatabase.get_fruit_data(prev_id)
			stats_lbl.text += "\n🔒 Requisito: comprar " + str(prev_data["name"])
		stats_lbl.add_theme_font_size_override("font_size", 13)
		stats_lbl.modulate = Color(0.75, 0.85, 0.9)
		var text_vbox := VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.add_child(name_lbl)
		text_vbox.add_child(stats_lbl)

		var buy_btn := Button.new()
		buy_btn.custom_minimum_size = Vector2(130, 48)
		var captured_id: String = str(fruit_id)
		buy_btn.pressed.connect(func():
			_on_buy_fruit(captured_id, price)
		)

		hbox.add_child(icon_lbl)
		hbox.add_child(text_vbox)
		hbox.add_child(buy_btn)
		panel.add_child(hbox)
		fruit_items_container.add_child(panel)

		_fruit_rows[fruit_id] = {"buy_btn": buy_btn, "price": price}
		_sync_fruit_row(fruit_id)

# Update a single fruit row (unlocked state) after purchase, no rebuild
func _update_fruit_row(fruit_id: String) -> void:
	_sync_fruit_row(fruit_id)

func _rebuild_weapon_shop() -> void:
	for child in weapon_items_container.get_children():
		child.queue_free()

	var equipped_id: String = GameManager.run_equipped_knife
	for knife_id in StatsManager.knives_db.keys():
		var knife_data: Dictionary = StatsManager.knives_db[knife_id]
		var is_unlocked: bool = GameManager.is_knife_unlocked_this_run(knife_id)
		var is_equipped: bool = knife_id == equipped_id
		var price: int = StatsManager.get_weapon_price(int(knife_data["price"]))
		var prev_id: String = _get_prev_knife_id(str(knife_id))
		var chain_ok: bool = prev_id == "" or GameManager.is_knife_unlocked_this_run(prev_id)
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)

		var icon_lbl := Label.new()
		icon_lbl.text = str(knife_data["icon"])
		icon_lbl.add_theme_font_size_override("font_size", 30)
		var name_lbl := Label.new()
		name_lbl.text = str(knife_data["name"]) + (" [EN USO]" if is_equipped else "")
		name_lbl.add_theme_font_size_override("font_size", 18)
		var stats_lbl := Label.new()
		stats_lbl.text = "Daño: " + str(int(knife_data["damage"])) + "  |  Energía por golpe: " + str(knife_data["energy_cost"])
		if not chain_ok and not is_unlocked:
			var prev_knife: Dictionary = StatsManager.knives_db[prev_id]
			stats_lbl.text += "\n🔒 Requisito: comprar " + str(prev_knife["name"])
		stats_lbl.add_theme_font_size_override("font_size", 13)
		stats_lbl.modulate = Color(0.75, 0.85, 0.9)
		var desc_lbl := Label.new()
		desc_lbl.text = str(knife_data["description"])
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.modulate = Color(0.65, 0.75, 0.82)
		var text_vbox := VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.add_child(name_lbl)
		text_vbox.add_child(stats_lbl)
		text_vbox.add_child(desc_lbl)

		var action_btn := Button.new()
		action_btn.custom_minimum_size = Vector2(130, 48)
		var captured_id: String = str(knife_id)
		if is_equipped:
			action_btn.text = "EN USO"
			action_btn.disabled = true
		elif is_unlocked:
			action_btn.text = "EQUIPAR"
			action_btn.pressed.connect(func():
				GameManager.set_equipped_knife_this_run(captured_id)
				_rebuild_weapon_shop()
			)
		elif not chain_ok:
			action_btn.text = "🔒 BLOQUEADO"
			action_btn.disabled = true
		else:
			action_btn.text = "DESBLOQUEAR\n$" + _format_number(float(price))
			action_btn.disabled = GameManager.run_money < price
			action_btn.pressed.connect(func():
				if _get_prev_knife_id(captured_id) != "" and not GameManager.is_knife_unlocked_this_run(_get_prev_knife_id(captured_id)):
					_rebuild_weapon_shop()
					return
				if GameManager.spend_run_money(price):
					GameManager.unlock_knife_this_run(captured_id)
					GameManager.set_equipped_knife_this_run(captured_id)
					SoundManager.play_victory()
					_refresh_ui()
					_rebuild_weapon_shop()
			)

		hbox.add_child(icon_lbl)
		hbox.add_child(text_vbox)
		hbox.add_child(action_btn)
		weapon_items_container.add_child(hbox)

func _on_buy_fruit(fruit_id: String, price: int) -> void:
	var prev_id: String = _get_prev_fruit_id(fruit_id)
	if prev_id != "" and not GameManager.is_fruit_unlocked_this_run(prev_id):
		return
	if GameManager.spend_run_money(price):
		GameManager.unlock_fruit_this_run(fruit_id)
		SoundManager.play_victory()
		_refresh_ui()
		_update_fruit_row(fruit_id)
		_refresh_affordability()

func _on_buy_upgrade(upgrade_id: String) -> void:
	var cost: int = StatsManager.get_run_upgrade_cost(upgrade_id)
	if GameManager.spend_run_money(cost):
		SoundManager.play_coin()
		StatsManager.buy_run_upgrade(upgrade_id)
		_refresh_ui()
		_update_upgrade_row(upgrade_id)
		_refresh_affordability()

func _on_stats_pressed() -> void:
	SoundManager.play_click()
	emit_signal("open_stats_requested")

func _on_continue_pressed() -> void:
	SoundManager.play_click()
	visible = false
	emit_signal("start_next_order_requested")
	emit_signal("modal_closed")

func _on_close_pressed() -> void:
	SoundManager.play_click()
	visible = false
	emit_signal("start_next_order_requested")
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
