extends Control
# ============================================================================
# ResultsModal: pantalla final que aparece cuando el negocio quiebra (o el
# jugador renuncia). Muestra el resumen del negocio y la reputación ganada
# (calculada en GameManager.end_run_failed).
# ============================================================================

signal return_to_menu_requested

@onready var orders_label: Label = $Panel/VBox/StatsVBox/OrdersLabel
@onready var money_label: Label = $Panel/VBox/StatsVBox/MoneyLabel
@onready var fruits_label: Label = $Panel/VBox/StatsVBox/FruitsLabel
@onready var jackpots_label: Label = $Panel/VBox/StatsVBox/JackpotsLabel
@onready var best_order_label: Label = $Panel/VBox/StatsVBox/BestOrderLabel
@onready var prestige_earned_label: Label = $Panel/VBox/PrestigeContainer/VBox/PrestigeEarnedLabel
@onready var total_prestige_label: Label = $Panel/VBox/PrestigeContainer/VBox/TotalPrestigeLabel
@onready var continue_btn: Button = $Panel/VBox/ContinueButton

func _ready() -> void:
	visible = false
	continue_btn.pressed.connect(_on_continue_pressed)

func open_modal(summary: Dictionary) -> void:
	visible = true
	UiTheme.pop_in($Panel)
	orders_label.text = "📋 Días completados: " + str(summary.get("completed_orders", 0))
	money_label.text = "💰 Ganancias generadas: $" + _format_number(float(summary.get("money_generated", 0.0)))
	fruits_label.text = "🍉 Frutas cortadas: " + str(summary.get("fruits_cut", 0))
	jackpots_label.text = "⭐ Grandes ventas conseguidas: " + str(summary.get("jackpots", 0))
	best_order_label.text = "🏆 Mejor día alcanzado: #" + str(summary.get("best_order", 1))
	prestige_earned_label.text = "+ " + str(summary.get("earned_prestige", 0)) + " ⭐"
	total_prestige_label.text = "⭐ Reputación total acumulada: " + str(summary.get("total_prestige", 0))

func _on_continue_pressed() -> void:
	SoundManager.play_click()
	visible = false
	emit_signal("return_to_menu_requested")

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
