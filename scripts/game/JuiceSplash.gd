extends CPUParticles2D
class_name JuiceSplash
# ============================================================================
# JuiceSplash: pequena explosion de "zumo" del color de la fruta que acompaña
# cada corte. Un solo burst radial (one_shot) que cae un instante con gravedad
# y se auto-libera al terminar.
#
# Uso: instancia a la posicion del corte y llama setup(color, cantidad).
# ============================================================================

func _ready() -> void:
	finished.connect(queue_free)
	set_emitting(true)

# Aplica color (tintado de la fruta) y cantidad proporcional al radio, con algo
# de variacion de tamano para que el burst no se vea repetido.
func setup(color: Color, p_amount: int = 16) -> void:
	modulate = color
	amount = clampi(p_amount, 8, 48)
	# Sin textura la particula es un cuadrado 1x1 px: hay que escalarla para
	# que los trozos de zumo sean visibles (~4-8 px con variacion).
	scale_amount_min = 3.5 * randf_range(0.8, 1.2)
	scale_amount_max = 7.0 * randf_range(0.8, 1.2)