class_name KnifeData
extends Resource
# ============================================================================
# KnifeData: plantilla de datos de un arma. En la práctica, StatsManager.gd
# guarda las armas directamente como Dictionary (knives_db) en vez de usar
# este resource, pero se mantiene por compatibilidad. Para balancear las
# armas edita StatsManager.knives_db, no este archivo.
# ============================================================================

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var damage: float = 10.0
@export var energy_cost: float = 5.0
@export var price: int = 0
@export var icon_emoji: String = "🔪"
