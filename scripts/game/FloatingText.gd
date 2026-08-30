extends Node2D
# ============================================================================
# FloatingText: texto flotante animado (ej. "+$5", "-12", "¡CRÍTICO!") que
# aparece brevemente y desaparece. Puramente visual, sin valores de balance.
# ============================================================================

@onready var label: Label = $Label

func _ready() -> void:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 5)

func setup(text: String, color: Color, scale_multiplier: float = 1.0, duration: float = 0.75) -> void:
	label.text = text
	label.modulate = color
	scale = Vector2(scale_multiplier, scale_multiplier)

	# Optimized tween without await
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	
	var target_pos: Vector2 = position + Vector2(randf_range(-30.0, 30.0), -60.0 * scale_multiplier)
	tween.tween_property(self, "position", target_pos, duration).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", scale * 1.25, duration * 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	tween.tween_callback(func():
		if is_instance_valid(self):
			var fade_tween: Tween = create_tween()
			fade_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			fade_tween.tween_property(self, "modulate:a", 0.0, duration * 0.7)
			fade_tween.tween_callback(func(): 
				if is_instance_valid(self):
					queue_free()
			)
	)
