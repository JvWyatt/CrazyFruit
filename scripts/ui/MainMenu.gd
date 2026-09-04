extends Control
# ============================================================================
# MainMenu: pantalla inicial del juego (Jugar, Tienda de Prestigio, Progreso,
# Comodines, Ajustes, Reiniciar Progreso). Solo emite señales; Main.gd decide
# qué hacer con cada botón presionado. Los sliders de ajustes viven en una
# SettingsSection reutilizable y el diálogo de reiniciar es un ConfirmDialog
# estilizado (no el ConfirmationDialog feo de Godot).
# ============================================================================

signal start_game_requested
signal open_prestige_shop_requested
signal open_progress_requested
signal open_cards_requested
signal open_achievements_requested

@onready var play_button: Button = $CenterVBox/ButtonsVBox/PlayButton
@onready var prestige_shop_button: Button = $CenterVBox/ButtonsVBox/PrestigeShopButton
@onready var progress_button: Button = $CenterVBox/ButtonsVBox/ProgressButton
@onready var achievements_button: Button = $CenterVBox/ButtonsVBox/AchievementsButton
@onready var cards_button: Button = $CenterVBox/ButtonsVBox/CardsButton
@onready var settings_button: Button = $CenterVBox/ButtonsVBox/SettingsButton
@onready var reset_button: Button = $CenterVBox/ButtonsVBox/ResetButton
@onready var reset_confirm_dialog: ConfirmDialog = $ResetConfirmDialog
@onready var version_label: Label = $VersionLabel

@onready var settings_panel: Control = $SettingsPanel
@onready var settings_card: PanelContainer = $SettingsPanel/SettingsCard
@onready var settings_section: SettingsSection = $SettingsPanel/SettingsCard/VBox/SettingsSection
@onready var back_button: Button = $SettingsPanel/SettingsCard/VBox/BackButton
@onready var goal_label: Label = $CenterVBox/TitleVBox/GoalLabel

var _anim_started: bool = false

# Pool de frases retadoras que rotan en el menú principal mientras el jugador
# intenta llegar a los 100 días.
const CHALLENGE_PHRASES: Array[String] = [
	"100 días, ¿eso está pelado?",
	"100 días, pan comido... ¿o fruta?",
	"100 días, mucha fruta, poco tiempo.",
	"100 días y ni una excusa.",
	"100 días para pelar este problema.",
	"100 días sin acabar hecho puré.",
	"100 días sin perder el filo.",
	"100 días para no hacerte papilla.",
	"100 días y ni una fruta podrida.",
]
var _phrase_index: int = 0

func _ready() -> void:
	version_label.text = "v%s" % ProjectSettings.get_setting("application/config/version")
	play_button.pressed.connect(_on_play_pressed)
	prestige_shop_button.pressed.connect(_on_prestige_shop_pressed)
	progress_button.pressed.connect(_on_progress_pressed)
	achievements_button.pressed.connect(_on_achievements_pressed)
	cards_button.pressed.connect(_on_cards_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	reset_confirm_dialog.confirmed.connect(_on_reset_confirmed)
	back_button.pressed.connect(_on_settings_closed)
	call_deferred("_maybe_animate")

func _notification(what: int) -> void:
	# La animación de entrada corre UNA sola vez. Repetirla en cada
	# NOTIFICATION_VISIBILITY_CHANGED (muy frecuente en Android al superponer
	# modales) creaba tweens en colisión sobre el menú, que seguía visible tras
	# los botones (Prestigio/Progreso/Comodines/Ajustes). Al no re-disparchar,
	# se elimina ese churn de animaciones que solo se daba en el menú principal.
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree():
		_rotate_phrase()
		if not _anim_started:
			_anim_started = true
			call_deferred("_maybe_animate")

func _rotate_phrase() -> void:
	if goal_label == null or CHALLENGE_PHRASES.is_empty():
		return
	var phrase: String = CHALLENGE_PHRASES[_phrase_index % CHALLENGE_PHRASES.size()]
	_phrase_index += 1
	goal_label.text = "🎯 " + phrase

func _maybe_animate() -> void:
	if not is_visible_in_tree():
		return
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

func _on_achievements_pressed() -> void:
	SoundManager.play_click()
	emit_signal("open_achievements_requested")

func _on_cards_pressed() -> void:
	SoundManager.play_click()
	emit_signal("open_cards_requested")

func _on_settings_pressed() -> void:
	SoundManager.play_click()
	settings_section.sync()
	settings_panel.visible = true
	UiTheme.pop_in(settings_card)

func _on_settings_closed() -> void:
	SoundManager.play_click()
	settings_panel.visible = false

func _on_reset_pressed() -> void:
	SoundManager.play_click()
	reset_confirm_dialog.open(
		"REINICIAR PROGRESO",
		"¿Seguro que quieres reiniciar todo el progreso permanente?\nEsta acción no se puede deshacer.",
		"REINICIAR",
		"CANCELAR"
	)

func _on_reset_confirmed() -> void:
	SaveManager.reset_save()
