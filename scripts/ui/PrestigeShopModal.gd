extends Control
# ============================================================================
# PrestigeShopModal: tienda de mejoras PERMANENTES compradas con reputación
# (prestige_points en SaveManager). Los precios/efectos de cada mejora están
# en StatsManager.prestige_definitions.
# ============================================================================

@onready var prestige_label: Label = $Panel/VBox/HeaderHBox/PrestigeLabel
@onready var close_button: Button = $Panel/VBox/HeaderHBox/CloseButton
@onready var items_container: ResponsiveGrid = $Panel/VBox/ScrollContainer/ItemsGrid

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	SaveManager.prestige_changed.connect(func(_p): _refresh_ui())
	StatsManager.stats_updated.connect(_refresh_ui)

func open_modal() -> void:
	visible = true
	UiTheme.pop_in($Panel)
	_refresh_ui()

func _refresh_ui() -> void:
	prestige_label.text = "⭐ " + ("%.2f" % SaveManager.get_prestige_points()) + " Rep."

	for child in items_container.get_children():
		child.queue_free()

	for key in StatsManager.prestige_definitions.keys():
		var def: PrestigeUpgradeData = StatsManager.prestige_definitions[key]
		var level: int = SaveManager.get_prestige_level(key)
		var cost: float = StatsManager.get_prestige_upgrade_cost(key)
		var can_buy: bool = SaveManager.get_prestige_points() >= cost

		# Tarjeta compacta del grid (scripts/ui/ShopCard.gd). Todo el diseno de
		# la tarjeta vive ahi; aqui solo se conectan los datos y la compra.
		var card := ShopCard.create()
		card.setup(
			def.icon,
			def.name,
			"Nivel " + str(level),
			def.desc,
			("%.2f" % cost) + " ⭐",
			can_buy
		)

		var captured_key = key
		card.action_button.pressed.connect(func():
			if StatsManager.buy_prestige_upgrade(captured_key):
				SoundManager.play_victory()
				_refresh_ui()
		)

		items_container.add_child(card)

func _on_close_pressed() -> void:
	SoundManager.play_click()
	visible = false
