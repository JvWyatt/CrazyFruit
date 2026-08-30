class_name UpgradeCardData
extends Resource
# ============================================================================
# UpgradeCardData: plantilla de datos de un comodín/carta. Igual que
# KnifeData, en la práctica CardDatabase.gd genera las cartas como
# Dictionary. Para balancear los comodines edita CardDatabase.gd.
# ============================================================================

@export var id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var icon_emoji: String = "✨"
@export var rarity: String = "Común"
@export var rarity_color: Color = Color(0.3, 0.7, 1.0)
@export var effect_type: String = ""
@export var effect_value: float = 0.0
