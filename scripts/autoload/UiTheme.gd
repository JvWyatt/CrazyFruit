extends Node
# ============================================================================
# UiTheme: paleta central + tema global + micro-interacciones para la
# interfaz. Construye un Theme por código (más robusto que un .tres a mano)
# y lo aplica al root para que TODOS los botones/paneles/barras hereden el
# estilo (píldoras, bordes, relieve, sombras) sin tocar cada widget.
# También expone helpers para la UI generada por código.
# ============================================================================

const COLOR_BG: Color = Color(0.055, 0.071, 0.125)
const COLOR_PANEL: Color = Color(0.078, 0.102, 0.18)
const COLOR_ROW: Color = Color(0.102, 0.129, 0.22)
const COLOR_BORDER: Color = Color(0.196, 0.251, 0.42)
const COLOR_ACCENT: Color = Color(1.0, 0.835, 0.29)
const COLOR_TEXT: Color = Color(0.9, 0.93, 0.98)
const COLOR_TEXT_DIM: Color = Color(0.65, 0.72, 0.82)
const COLOR_SUCCESS: Color = Color(0.31, 0.84, 0.62)
const COLOR_DANGER: Color = Color(1.0, 0.35, 0.37)

func _ready() -> void:
	_install_theme()

# ---------------------------------------------------------------------------
# Tema global
# ---------------------------------------------------------------------------

func _install_theme() -> void:
	var theme := Theme.new()

	# Botones: esquinas claramente redondeadas con borde, relieve inferior y sombra.
# (Radio fijo 18: una píldora con radio 999 en botones anchos se ve como un
# rectángulo plano; con radio 18 el redondeo es evidente en todas las pantallas.)
	var btn_normal := _pill_style(Color(0.16, 0.2, 0.34), Color(0.45, 0.55, 0.85, 0.9), 3)
	var btn_hover := _pill_style(Color(0.23, 0.3, 0.5), Color(0.72, 0.8, 0.97, 1.0), 4)
	var btn_pressed := _pill_style(Color(0.085, 0.11, 0.2), Color(0.95, 0.78, 0.32, 1.0), 1)
	var btn_disabled := _pill_style(Color(0.1, 0.12, 0.17), Color(0.18, 0.21, 0.3, 1.0), 0)
	var btn_focus := _pill_style(Color(0, 0, 0, 0), Color(0.3, 0.6, 1.0, 0.9), 0)
	btn_focus.border_width_left = 2
	btn_focus.border_width_top = 2
	btn_focus.border_width_right = 2
	btn_focus.border_width_bottom = 2

	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)
	theme.set_stylebox("focus", "Button", btn_focus)
	theme.set_stylebox("hover_pressed", "Button", btn_pressed)

	theme.set_color("font_color", "Button", Color(0.94, 0.96, 1.0))
	theme.set_color("font_hover_color", "Button", Color(1.0, 0.96, 0.78))
	theme.set_color("font_pressed_color", "Button", Color(1.0, 0.86, 0.4))
	theme.set_color("font_disabled_color", "Button", Color(0.45, 0.5, 0.6, 0.7))
	theme.set_constant("separation", "Button", 0)

	# Sliders horizontales (ajustes): carril oscuro, relleno verde y pomo dorado.
	theme.set_stylebox("slider", "HSlider", _box_style(Color(0.09, 0.11, 0.17), Color(0.16, 0.21, 0.34, 0.8), 5))
	theme.set_stylebox("grabber_area", "HSlider", _box_style(Color(0.31, 0.84, 0.62), Color(0, 0, 0, 0), 5))
	theme.set_stylebox("grabber_area_highlight", "HSlider", _box_style(Color(0.34, 0.92, 0.68), Color(0, 0, 0, 0), 5))
	theme.set_stylebox("grabber", "HSlider", _box_style(Color(1.0, 0.835, 0.29), Color(0.8, 0.6, 0.2, 0.9), 999))
	theme.set_stylebox("grabber_highlight", "HSlider", _box_style(Color(1.0, 0.9, 0.5), Color(0.8, 0.6, 0.2, 0.9), 999))

	# Barras de progreso (fondo con borde sutil + relleno redondeado).
	theme.set_stylebox("background", "ProgressBar", _box_style(Color(0.09, 0.11, 0.17), Color(0.2, 0.26, 0.42, 0.8), 8))
	theme.set_stylebox("fill", "ProgressBar", _box_style(Color(0.31, 0.84, 0.62), Color(0.31, 0.84, 0.62, 0.0), 8))

	# Pestañas redondeadas (p.ej. Mejoras/Frutería/Armas de la tienda de mejoras).
	theme.set_stylebox("tab_selected", "TabContainer", _box_style(Color(0.16, 0.2, 0.34), Color(0.45, 0.55, 0.85, 0.9), 12, 2))
	theme.set_stylebox("tab_unselected", "TabContainer", _box_style(Color(0.09, 0.11, 0.17), Color(0.2, 0.26, 0.42, 0.6), 12))
	theme.set_stylebox("tab_hovered", "TabContainer", _box_style(Color(0.12, 0.15, 0.24), Color(0.4, 0.5, 0.75, 0.7), 12))
	theme.set_stylebox("tab_focused", "TabContainer", _box_style(Color(0.12, 0.15, 0.24), Color(0.3, 0.6, 1.0, 0.9), 12, 2))
	theme.set_stylebox("panel", "TabContainer", _box_style(COLOR_PANEL, Color(0.28, 0.36, 0.58, 0.8), 14))
	theme.set_color("font_color_selected", "TabContainer", COLOR_TEXT)
	theme.set_color("font_unselected_color", "TabContainer", COLOR_TEXT_DIM)
	theme.set_color("font_hovered_color", "TabContainer", COLOR_TEXT)
	theme.set_font_size("font_size", "TabContainer", 16)
	theme.set_constant("tab_separation", "TabContainer", 2)

	# Paneles por defecto (tarjeta oscura con borde y sombra).
	theme.set_stylebox("panel", "PanelContainer", _box_style(COLOR_PANEL, Color(0.28, 0.36, 0.58), 14, 8))

	# Paneles de ventanas/diálogos.
	theme.set_stylebox("panel", "Window", _box_style(Color(0.1, 0.13, 0.22, 0.99), Color(0.32, 0.41, 0.63), 16, 10))

	# Scrollbars verticales.
	var scroll_track := _box_style(Color(0.07, 0.09, 0.15), Color(0, 0, 0, 0), 4)
	var scroll_grab := _box_style(Color(0.34, 0.43, 0.66), Color(0, 0, 0, 0), 4)
	var scroll_grab_hi := _box_style(Color(0.48, 0.6, 0.88), Color(0, 0, 0, 0), 4)
	theme.set_stylebox("scroll", "VScrollBar", scroll_track)
	theme.set_stylebox("grabber", "VScrollBar", scroll_grab)
	theme.set_stylebox("grabber_highlight", "VScrollBar", scroll_grab_hi)
	theme.set_stylebox("grabber_pressed", "VScrollBar", scroll_grab_hi)

	# Texto por defecto.
	theme.set_color("font_color", "Label", COLOR_TEXT)
	theme.set_font_size("font_size", "Label", 18)

	get_tree().root.theme = theme

func _pill_style(bg: Color, border: Color, shadow_size: int) -> StyleBoxFlat:
	var sb := _box_style(bg, border, 18, shadow_size)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb

func _box_style(bg: Color, border: Color, radius: int, shadow_size: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = border
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = shadow_size
	sb.shadow_offset = Vector2(0, 2)
	return sb

# ---------------------------------------------------------------------------
# Helpers para la UI generada por código
# ---------------------------------------------------------------------------

# Tarjeta/panel con borde y sombra, usada por la UI generada por código.
func card_style(border_color: Color = COLOR_BORDER, bg_color: Color = COLOR_ROW) -> StyleBoxFlat:
	var style := _box_style(bg_color, border_color, 14, 6)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

# Da un estilo de tarjeta consistente a un PanelContainer sin sobrescribir nada.
func apply_card(panel: PanelContainer, border_color: Color = COLOR_BORDER, bg_color: Color = COLOR_ROW) -> void:
	panel.add_theme_stylebox_override("panel", card_style(border_color, bg_color))

# Formato de dinero consistente: enteros simplificados con sufijos de letras
# para cantidades grandes (ej: 1250 -> "1.2K", 2500000 -> "2.5M",
# 3500000000 -> "3.5B", 4000000000000 -> "4T"). Usado en TODA la UI (HUD,
# tiendas, resúmenes) para evitar formatos dispersos.
func format_money(value: float) -> String:
	var v: float = float(value)
	var suffixes: Array = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp"]
	var idx: int = 0
	while v >= 1000.0 and idx < suffixes.size() - 1:
		v /= 1000.0
		idx += 1
	if idx > 0:
		return str(snappedf(v, 0.1)) + suffixes[idx]
	return str(int(round(v)))

# Entrada suave de modales/paneles: fade + escala con rebote suave.
func pop_in(control: Control) -> void:
	if control == null:
		return
	control.pivot_offset = control.size * 0.5
	control.modulate.a = 0.0
	control.scale = Vector2(0.96, 0.96)
	var tween := control.create_tween()
	tween.set_parallel(true)
	tween.tween_property(control, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# Pulso de escala en una etiqueta (p.ej. al subir el dinero).
func pulse_label(label: Control, amount: float = 1.14) -> void:
	if label == null:
		return
	label.pivot_offset = label.size * 0.5
	var tween := label.create_tween()
	tween.tween_property(label, "scale", Vector2(amount, amount), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

# Ráfaga de confeti para momentos de victoria (recibe el panel contenedor y
# una posición en coordenadas locales del panel).
func confetti_burst(parent: Node, local_position: Vector2, amount: int = 90) -> void:
	if parent == null:
		return
	var particles := CPUParticles2D.new()
	particles.position = local_position
	particles.emitting = true
	particles.amount = amount
	particles.lifetime = 1.4
	particles.explosiveness = 1.0
	particles.one_shot = true
	particles.spread = 160.0
	particles.gravity = Vector2(0, 360)
	particles.initial_velocity_min = 260.0
	particles.initial_velocity_max = 460.0
	particles.angular_velocity_min = -320.0
	particles.angular_velocity_max = 320.0
	particles.damping_min = 40.0
	particles.damping_max = 160.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	ramp.colors = PackedColorArray([
		Color(1.0, 0.835, 0.29),
		Color(0.31, 0.84, 0.62),
		Color(0.3, 0.7, 1.0),
		Color(1.0, 0.45, 0.55),
		Color(0.85, 0.5, 1.0)
	])
	particles.color_ramp = ramp
	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0, 1), 0, 0, 0, 0)
	scale_curve.add_point(Vector2(1, 0.4), 0, 0, 0, 0)
	particles.scale_amount_curve = scale_curve
	parent.add_child(particles)
	_cleanup_confetti_later(particles)

func _cleanup_confetti_later(particles: Node) -> void:
	await get_tree().create_timer(2.4).timeout
	if is_instance_valid(particles):
		particles.queue_free()
