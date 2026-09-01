extends Control
# ============================================================================
# MainMenu: pantalla inicial del juego (Jugar, Tienda de Prestigio, Progreso,
# Comodines, Reiniciar Progreso). Solo emite señales; Main.gd decide qué
# hacer con cada botón presionado.
# ============================================================================

signal start_game_requested
signal open_prestige_shop_requested
signal open_progress_requested
signal open_cards_requested

@onready var play_button: Button = $CenterVBox/ButtonsVBox/PlayButton
@onready var prestige_shop_button: Button = $CenterVBox/ButtonsVBox/PrestigeShopButton
@onready var progress_button: Button = $CenterVBox/ButtonsVBox/ProgressButton
@onready var cards_button: Button = $CenterVBox/ButtonsVBox/CardsButton
@onready var reset_button: Button = $CenterVBox/ButtonsVBox/ResetButton
@onready var reset_confirm_dialog: ConfirmationDialog = $ResetConfirmDialog
@onready var version_label: Label = $VersionLabel

var _last_anim_time: int = -10000

func _ready() -> void:
	version_label.text = "v%s" % ProjectSettings.get_setting("application/config/version")
	play_button.pressed.connect(_on_play_pressed)
	prestige_shop_button.pressed.connect(_on_prestige_shop_pressed)
	progress_button.pressed.connect(_on_progress_pressed)
	cards_button.pressed.connect(_on_cards_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	reset_confirm_dialog.confirmed.connect(_on_reset_confirmed)
	call_deferred("_maybe_animate")

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree():
		_maybe_animate()

func _maybe_animate() -> void:
	if not is_visible_in_tree():
		return
	if Time.get_ticks_msec() < _last_anim_time + 400:
		return
	_last_anim_time = Time.get_ticks_msec()
	animate_in()

func animate_in() -> void:
	UiTheme.pop_in($CenterVBox)

func _on_play_pressed() -> void:
	SoundManager.play_click()
	emit_signal("start_game_requested")

func _on_prestige_shop_pressed() -> void:
	SoundManager.play_click()
	emit_signal("open_prestige_shop_requested")

func _on_progress_pressed() -> void:
	SoundManager.play_click()
	emit_signal("open_progress_requested")

func _on_cards_pressed() -> void:
	SoundManager.play_click()
	emit_signal("open_cards_requested")

func _on_reset_pressed() -> void:
	SoundManager.play_click()
	reset_confirm_dialog.popup_centered()

func _on_reset_confirmed() -> void:
	SaveManager.reset_save()
