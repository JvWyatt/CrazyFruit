extends Control
# ============================================================================
# HUD: la interfaz que se ve MIENTRAS juegas (dinero, pedido, barra de
# energía, tiempo restante de la ronda, frecuencia de lanzamiento, arma
# equipada y botones de Stats/Pausa). Solo muestra datos que vienen de
# GameManager/StatsManager; no decide reglas.
#
# El botón de pausa abre el PausePanel: pausa la ronda (pause_turn), permite
# ajustar el volumen (SettingsSection), continuar jugando o salir del negocio
# (con ConfirmDialog estilizado antes de renunciar).
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
@onready var pause_btn: Button = $BottomContainer/ButtonsHBox/PauseButton
@onready var pause_panel: Control = $PausePanel
@onready var pause_card: PanelContainer = $PausePanel/Card
@onready var pause_day_label: Label = $PausePanel/Card/PauseVBox/PauseDayLabel
@onready var continue_btn: Button = $PausePanel/Card/PauseVBox/ContinueButton
@onready var settings_btn: Button = $PausePanel/Card/PauseVBox/SettingsButton
@onready var pause_quit_btn: Button = $PausePanel/Card/PauseVBox/PauseQuitButton
@onready var pause_vbox: VBoxContainer = $PausePanel/Card/PauseVBox
@onready var settings_vbox: VBoxContainer = $PausePanel/Card/SettingsVBox
@onready var settings_section: SettingsSection = $PausePanel/Card/SettingsVBox/SettingsSection
@onready var settings_back_btn: Button = $PausePanel/Card/SettingsVBox/SettingsBackButton
@onready var pause_confirm_dialog: ConfirmDialog = $PauseConfirmDialog

func _ready() -> void:
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.order_progress_changed.connect(_on_order_progress_changed)
	GameManager.energy_changed.connect(_on_energy_changed)
	GameManager.round_time_changed.connect(_on_round_time_changed)
	StatsManager.stats_updated.connect(_on_stats_updated)
	GameManager.run_knife_equipped.connect(func(_id): _update_knife_display())

	stats_btn.pressed.connect(_on_stats_button_pressed)
	pause_btn.pressed.connect(_on_pause_button_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	settings_btn.pressed.connect(_on_settings_button_pressed)
	settings_back_btn.pressed.connect(_on_settings_back_pressed)
	pause_quit_btn.pressed.connect(_on_pause_quit_pressed)
	pause_confirm_dialog.confirmed.connect(_on_quit_confirmed)
	_update_knife_display()
	_update_launch_rate_display()

func format_damage(value: float) -> String:
	return str(snappedf(value, 0.1))

func _update_knife_display() -> void:
	var knife_data: Dictionary = StatsManager.get_equipped_knife_data()
	var knife_name: String = str(knife_data.get("name", "Utensilio básico"))
	var knife_icon: String = str(knife_data.get("icon", "🔪"))
	knife_label.text = knife_icon + " " + knife_name + " (⚔️" + format_damage(StatsManager.get_final_damage()) + ")"

func _on_stats_updated() -> void:
	_update_knife_display()
	_update_launch_rate_display()

func _update_launch_rate_display() -> void:
	var rate: float = StatsManager.get_final_launch_rate()
	launch_rate_label.text = "🍉 " + str(snappedf(rate, 0.1)) + " frutas/s"

var _last_money: float = -1.0

func _on_money_changed(amount: float) -> void:
	money_label.text = "💰 $" + UiTheme.format_money(amount)
	if amount > _last_money and _last_money >= 0.0:
		UiTheme.pulse_label(money_label, 1.12)
	_last_money = amount

func _on_order_progress_changed(progress: float, target: float) -> void:
	order_label.text = "📋 Día " + str(GameManager.current_order)
	status_info_label.text = "💼 Negocio " + str(SaveManager.save_data.get("days_started", 1))
	order_progress_bar.max_value = target
	order_progress_bar.value = min(progress, target)
	order_progress_label.text = "$" + UiTheme.format_money(progress) + " / $" + UiTheme.format_money(target)

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

# --- Pausa --------------------------------------------------------------

func _on_pause_button_pressed() -> void:
	SoundManager.play_click()
	GameManager.pause_turn()
	pause_day_label.text = "📋 Día " + str(GameManager.current_order)
	pause_vbox.visible = true
	settings_vbox.visible = false
	pause_panel.visible = true
	UiTheme.pop_in(pause_card)

func _on_continue_pressed() -> void:
	SoundManager.play_click()
	pause_panel.visible = false
	if GameManager.current_state == GameManager.GameState.PLAYING:
		GameManager.resume_turn()

func _on_settings_button_pressed() -> void:
	SoundManager.play_click()
	settings_section.sync()
	pause_vbox.visible = false
	settings_vbox.visible = true

func _on_settings_back_pressed() -> void:
	SoundManager.play_click()
	settings_vbox.visible = false
	pause_vbox.visible = true

func _on_pause_quit_pressed() -> void:
	SoundManager.play_click()
	pause_confirm_dialog.open(
		"RENUNCIAR AL NEGOCIO",
		"¿Seguro que quieres renunciar a este negocio?\nPerderás el progreso del día actual.",
		"RENUNCIAR",
		"CONTINUAR JUGANDO"
	)

func _on_quit_confirmed() -> void:
	pause_panel.visible = false
	emit_signal("quit_run_requested")
