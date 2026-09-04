class_name FruitData
extends Resource
# ============================================================================
# FruitData: los datos "ya calculados" de UNA fruta concreta en juego (con
# multiplicadores de comodines ya aplicados). Creado por
# FruitDatabase.create_fruit_resource(). No edites los valores por defecto
# aquí para balancear el juego: eso se hace en FruitDatabase.gd.
# ============================================================================

@export var id: String = ""
@export var display_name: String = ""
@export var icon_emoji: String = "🍎"
@export var max_hp: float = 10.0
@export var min_reward: float = 1.0
@export var max_reward: float = 3.0
@export var jackpot_chance: float = 0.0
@export var unlock_order: int = 1
@export var base_color: Color = Color(0.9, 0.2, 0.2)
@export var inner_color: Color = Color(1.0, 0.4, 0.4)
@export var radius: float = 40.0
