extends Control
# ============================================================================
# HUD: la interfaz que se ve MIENTRAS juegas (dinero, pedido, barra de
# energía, tiempo restante de la ronda, frecuencia de lanzamiento, arma
# equipada y botones de Stats/Salir). Solo muestra datos que vienen de
# GameManager/StatsManager; no decide reglas.
# ============================================================================

signal open_stats_requested
signal quit_run_requested

@onready var money_label: Label = $TopContainer/VBox/TopHBox/MoneyContainer/MoneyLabel
@onready var order_label: Label = $TopContainer/VBox/TopHBox/OrderContainer/OrderLabel
@onready var order_progress_bar: ProgressBar = $TopContainer/VBox/OrderProgressBar
@onready var order_progress_label: Label = $TopContainer/VBox/OrderProgressBar/OrderProgressLabel
@onready var status_info_label: Label = $TopContainer/VBox/StatusHBox/StatusInfoLabel
@onready var launch_rate_label: Label = $TopContainer/VBox/StatusHBox/LaunchRateLabel
@onready var round_time_label: Label = $TopContainer/VBox/RoundTimeLabel
@onready var energy_bar: ProgressBar = $TopContainer/VBox/EnergyContainer/EnergyBar
@onready var energy_label: Label = $TopContainer/VBox/EnergyContainer/EnergyBar/EnergyLabel
@onready var knife_label: Label = $BottomContainer/KnifeInfoLabel
@onready var stats_btn: Button = $BottomContainer/ButtonsHBox/StatsButton
@onready var quit_btn: Button = $BottomContainer/ButtonsHBox/QuitButton
@onready var quit_confirm_dialog: ConfirmationDialog = $QuitConfirmDialog

func _ready() -> void:
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.order_progress_changed.connect(_on_order_progress_changed)
	GameManager.energy_changed.connect(_on_energy_changed)
	GameManager.round_time_changed.connect(_on_round_time_changed)
	StatsManager.stats_updated.connect(_on_stats_updated)
	GameManager.run_knife_equipped.connect(func(_id): _update_knife_display())

	stats_btn.pressed.connect(_on_stats_button_pressed)
	quit_btn.pressed.connect(_on_quit_button_pressed)
	quit_confirm_dialog.confirmed.connect(_on_quit_confirmed)
	quit_confirm_dialog.canceled.connect(_on_quit_canceled)
	_update_knife_display()
	_update_launch_rate_display()

func _update_knife_display() -> void:
	var knife_data: Dictionary = StatsManager.get_equipped_knife_data()
	var knife_name: String = str(knife_data.get("name", "Utensilio básico"))
	var knife_icon: String = str(knife_data.get("icon", "🔪"))
	knife_label.text = knife_icon + " " + knife_name + " (⚔️" + str(int(round(StatsManager.get_final_damage()))) + ")"

func _on_stats_updated() -> void:
	_update_knife_display()
	_update_launch_rate_display()

func _update_launch_rate_display() -> void:
	var rate: float = StatsManager.get_final_launch_rate()
	launch_rate_label.text = "🍉 " + str(snappedf(rate, 0.1)) + " frutas/s"

var _last_money: float = -1.0

func _on_money_changed(amount: float) -> void:
	money_label.text = "💰 $" + _format_number(amount)
	if amount > _last_money and _last_money >= 0.0:
		UiTheme.pulse_label(money_label, 1.12)
	_last_money = amount

func _on_order_progress_changed(progress: float, target: float) -> void:
	order_label.text = "📋 Día " + str(GameManager.current_order)
	status_info_label.text = "💼 Negocio " + str(SaveManager.save_data.get("days_started", 1))
	order_progress_bar.max_value = target
	order_progress_bar.value = min(progress, target)
	order_progress_label.text = "$" + _format_number(progress) + " / $" + _format_number(target)

func _on_energy_changed(current_e: float, max_e: float) -> void:
	energy_bar.max_value = max_e
	energy_bar.value = current_e
	energy_label.text = "⚡ " + str(int(round(current_e))) + " / " + str(int(round(max_e)))

func _on_round_time_changed(time_left: float) -> void:
	var secs: int = ceili(maxf(0.0, time_left))
	round_time_label.text = "⏱ " + str(secs) + "s"
	round_time_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3) if secs <= 10 else Color(1.0, 0.95, 0.6))

func _on_stats_button_pressed() -> void:
	SoundManager.play_click()
	emit_signal("open_stats_requested")

func _on_quit_button_pressed() -> void:
	SoundManager.play_click()
	GameManager.pause_turn()
	quit_confirm_dialog.popup_centered()

func _on_quit_confirmed() -> void:
	emit_signal("quit_run_requested")

func _on_quit_canceled() -> void:
	if GameManager.current_state == GameManager.GameState.PLAYING:
		GameManager.resume_turn()

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
