extends Control
# ============================================================================
# OrderCompletionModal: pantalla de "pago de impuestos" que aparece al
# completar un pedido, antes de elegir comodín. Si no se puede pagar, el
# negocio termina (ver GameManager.end_run_failed).
# ============================================================================

signal objective_paid
signal objective_unpayable

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var message_label: Label = $Panel/VBox/MessageLabel
@onready var info_label: Label = $Panel/VBox/InfoLabel
@onready var button_container: HBoxContainer = $Panel/VBox/ButtonContainer
@onready var continue_btn: Button = $Panel/VBox/ButtonContainer/ContinueButton
@onready var fail_btn: Button = $Panel/VBox/ButtonContainer/FailButton

var current_order: int = 1
var required_payment: float = 0.0

func _ready() -> void:
	visible = false
	continue_btn.pressed.connect(_on_continue_pressed)
	fail_btn.pressed.connect(_on_fail_pressed)

func open_modal(order_num: int, target_money: float) -> void:
	current_order = order_num
	required_payment = target_money
	
	title_label.text = "📊 CIERRE DEL DÍA #" + str(order_num)
	
	var current_money: float = GameManager.run_money
	var can_pay: bool = current_money >= required_payment
	
	if can_pay:
		message_label.text = "✅ ¡Objetivos alcanzados! Impuesto a pagar:"
		info_label.text = "Dinero actual: $" + str(int(current_money)) + "\nImpuesto: $" + str(int(required_payment)) + "\nGanancia neta: $" + str(int(current_money - required_payment))
		fail_btn.visible = false
	else:
		message_label.text = "❌ No puedes pagar el impuesto del día"
		info_label.text = "Dinero actual: $" + str(int(current_money)) + "\nImpuesto requerido: $" + str(int(required_payment)) + "\nFaltante: $" + str(int(required_payment - current_money))
		continue_btn.visible = false
	
	visible = true
	UiTheme.pop_in(panel)

func _on_continue_pressed() -> void:
	# Deduct the objective amount as "tax"
	GameManager.spend_run_money(required_payment)
	visible = false
	emit_signal("objective_paid")

func _on_fail_pressed() -> void:
	visible = false
	emit_signal("objective_unpayable")
