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
@onready var streak_label: Label = $StreakPanel/VBox/StreakLabel
@onready var streak_bar: ProgressBar = $StreakPanel/VBox/StreakBar
@onready var streak_bar_label: Label = $StreakPanel/VBox/StreakBar/StreakBarLabel
@onready var milestone_label: Label = $MilestoneLabel
@onready var ach_toast: PanelContainer = $AchToast
@onready var ach_icon: Label = $AchToast/HBox/AchIcon
@onready var ach_title: Label = $AchToast/HBox/VBox/AchTitle
@onready var ach_desc: Label = $AchToast/HBox/VBox/AchDesc

# Pool de frases que se muestran en el centro al alcanzar un hito de racha.
const STREAK_PHRASES: Array[String] = [
	"¡YA PICASTE!",
	"¡BUEN CORTE!",
	"¡ESTO YA ES ENSALADA!",
	"¿TÚ DUERMES?",
	"¡DEJA ALGO PARA MAÑANA!",
	"¡FRUTALMENTE INSANO!",
]
var _milestone_tween: Tween

func _ready() -> void:
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.order_progress_changed.connect(_on_order_progress_changed)
	GameManager.energy_changed.connect(_on_energy_changed)
	GameManager.round_time_changed.connect(_on_round_time_changed)
	StatsManager.stats_updated.connect(_on_stats_updated)
	GameManager.run_knife_equipped.connect(func(_id): _update_knife_display())
	GameManager.streak_changed.connect(_on_streak_changed)
	GameManager.streak_milestone.connect(_on_streak_milestone)
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

	stats_btn.pressed.connect(_on_stats_button_pressed)
	pause_btn.pressed.connect(_on_pause_button_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	settings_btn.pressed.connect(_on_settings_button_pressed)
	settings_back_btn.pressed.connect(_on_settings_back_pressed)
	pause_quit_btn.pressed.connect(_on_pause_quit_pressed)
	pause_confirm_dialog.confirmed.connect(_on_quit_confirmed)
	_update_knife_display()
	_update_launch_rate_display()
	_on_streak_changed(GameManager.current_streak, GameManager.get_streak_multiplier())

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

# --- Racha de frutas --------------------------------------------------------

# Hitos ordenados ascendentemente para calcular progreso entre hitos.
const STREAK_ORDER: Array[int] = [5, 10, 20, 30, 50, 75, 100, 140, 190, 250, 320, 400, 490, 590, 700]

func _on_streak_changed(streak: int, multiplier: float) -> void:
	streak_label.text = "🔥 Racha: " + str(streak)
	var info: Dictionary = _streak_progress(streak)
	streak_bar.max_value = float(info["range"])
	streak_bar.value = float(info["progress"])
	streak_bar_label.text = ("→ " + str(info["next"])) if info["next"] > 0 else "→ MAX"
	streak_bar_label.text += "  (x" + str(snappedf(multiplier, 0.01)) + ")"

# Calcula el progreso de la barra de racha entre el hito anterior y el siguiente.
# Devuelve {range: intervalo, progress: avance dentro del intervalo, next: hito}.
func _streak_progress(streak: int) -> Dictionary:
	var last: int = STREAK_ORDER[STREAK_ORDER.size() - 1]
	if streak >= last:
		return {"range": 1, "progress": 1, "next": 0}
	var prev: int = 0
	var next: int = STREAK_ORDER[0]
	for m in STREAK_ORDER:
		if streak < m:
			next = m
			break
		prev = m
	var range: int = next - prev
	var progress: int = streak - prev
	return {"range": range, "progress": progress, "next": next}

func _on_streak_milestone(_milestone: int) -> void:
	if STREAK_PHRASES.is_empty():
		return
	var phrase: String = STREAK_PHRASES[randi() % STREAK_PHRASES.size()]
	milestone_label.text = "🔥 " + phrase
	milestone_label.modulate = Color(1, 1, 1, 1)
	milestone_label.scale = Vector2(0.8, 0.8)
	if _milestone_tween and _milestone_tween.is_valid():
		_milestone_tween.kill()
	_milestone_tween = create_tween()
	_milestone_tween.set_parallel(true)
	_milestone_tween.tween_property(milestone_label, "scale", Vector2(1.15, 1.15), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_milestone_tween.tween_property(milestone_label, "scale", Vector2(1.0, 1.0), 0.35).set_delay(0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_milestone_tween.tween_property(milestone_label, "modulate:a", 0.0, 0.5).set_delay(1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

# --- Notificación de logros -------------------------------------------------

var _ach_toast_tween: Tween
# Cola de logros pendientes de mostrar: si saltan varios a la vez (típico al
# completar un día), se muestran uno tras otro sin pisarse ni perderse.
var _ach_queue: Array[Dictionary] = []
var _ach_showing: bool = false

func _on_achievement_unlocked(_id: String, def: Dictionary) -> void:
	_ach_queue.append(def)
	if not _ach_showing:
		_show_next_achievement()

func _show_next_achievement() -> void:
	if _ach_queue.is_empty():
		_ach_showing = false
		return
	_ach_showing = true
	var def: Dictionary = _ach_queue.pop_front()
	ach_icon.text = str(def.get("icon", "🏆"))
	ach_title.text = "🎉 Logro desbloqueado"
	ach_desc.text = str(def.get("name", "¡Logro conseguido!"))
	# Entrada y salida discretas sin cortar la partida (fade + escala suave,
	# sin mover la posición para no chocar con los anchors del panel).
	if _ach_toast_tween and _ach_toast_tween.is_valid():
		_ach_toast_tween.kill()
	ach_toast.visible = true
	ach_toast.modulate = Color(1, 1, 1, 0)
	ach_toast.scale = Vector2(0.9, 0.9)
	ach_toast.pivot_offset = ach_toast.size * 0.5
	_ach_toast_tween = create_tween()
	_ach_toast_tween.set_parallel(true)
	_ach_toast_tween.tween_property(ach_toast, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_ach_toast_tween.tween_property(ach_toast, "scale", Vector2.ONE * 1.04, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_ach_toast_tween.chain().tween_interval(2.4)
	_ach_toast_tween.chain().tween_property(ach_toast, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_ach_toast_tween.chain().tween_callback(func():
		ach_toast.visible = false
		_show_next_achievement()
	)
	SoundManager.play_achievement()

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
