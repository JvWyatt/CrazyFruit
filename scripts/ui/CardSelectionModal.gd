extends Control
# ============================================================================
# CardSelectionModal: pantalla para elegir un comodín (carta) al completar
# un pedido. Muestra primero el resumen del día (conseguido, impuesto,
# ganancia) y debajo las cartas disponibles. Al completar el pedido el
# impuesto (objetivo del día) se paga automáticamente aquí; si no se puede
# pagar, el negocio termina (ver Main.gd).
# Las cartas disponibles vienen de CardDatabase.gd; al elegir una se aplica
# con StatsManager.apply_card_upgrade().
# ============================================================================

signal card_chosen(order_num: int)
signal unpayable

@onready var cards_container: VBoxContainer = $Panel/VBox/CardsScroll/CardsVBox
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var subtitle_label: Label = $Panel/VBox/SubtitleLabel
@onready var summary_panel: PanelContainer = $Panel/VBox/SummaryPanel
@onready var summary_title: Label = $Panel/VBox/SummaryPanel/SummaryVBox/SummaryTitle
@onready var earned_value: Label = $Panel/VBox/SummaryPanel/SummaryVBox/EarnedRow/EarnedValue
@onready var tax_value: Label = $Panel/VBox/SummaryPanel/SummaryVBox/TaxRow/TaxValue
@onready var profit_value: Label = $Panel/VBox/SummaryPanel/SummaryVBox/ProfitRow/ProfitValue
@onready var next_target_value: Label = $Panel/VBox/SummaryPanel/SummaryVBox/NextTargetRow/NextTargetValue

var current_completed_order: int = 1

func _ready() -> void:
	visible = false

func open_modal(order_completed_num: int) -> void:
	current_completed_order = order_completed_num
	visible = true
	UiTheme.pop_in($Panel)
	UiTheme.confetti_burst($Panel, Vector2(maxf($Panel.size.x * 0.5, 360.0), 70.0), 120)
	title_label.text = "🎉 ¡DÍA #" + str(order_completed_num) + " COMPLETADO!"
	subtitle_label.text = "Selecciona 1 comodín para mejorar tu negocio:"

	# Impuesto (objetivo del día): se paga automáticamente al completar el día.
	var tax: float = GameManager.order_target
	var earned: float = GameManager.order_progress

	if not GameManager.spend_run_money(tax):
		# No se puede pagar el impuesto: negocio en quiebra.
		visible = false
		emit_signal("unpayable")
		return

	# Resumen del día: conseguido, impuesto y ganancia neta.
	earned_value.text = "$" + UiTheme.format_money(earned)
	tax_value.text = "$" + UiTheme.format_money(tax)
	var profit: float = earned - tax
	profit_value.text = "$" + UiTheme.format_money(profit)
	profit_value.modulate = Color(0.6, 0.95, 0.6, 1) if profit >= 0.0 else Color(1, 0.6, 0.6, 1)

	# Vista previa del objetivo del próximo día (debajo del impuesto del resumen).
	next_target_value.text = "$" + UiTheme.format_money(GameManager.get_order_target_for(GameManager.current_order + 1))

	for child in cards_container.get_children():
		child.queue_free()

	var cards: Array[Dictionary] = CardDatabase.get_random_cards(3)

	for card_data in cards:
		var card_panel := PanelContainer.new()
		UiTheme.apply_card(card_panel, card_data["color"])

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 16)

		var icon_lbl := Label.new()
		icon_lbl.text = str(card_data["icon"])
		icon_lbl.add_theme_font_size_override("font_size", 38)
		icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		var text_vbox := VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.custom_minimum_size.x = 0

		var rarity_lbl := Label.new()
		rarity_lbl.text = "[" + str(card_data["rarity"]).to_upper() + "]"
		rarity_lbl.add_theme_font_size_override("font_size", 13)
		rarity_lbl.modulate = card_data["color"]

		var name_lbl := Label.new()
		name_lbl.text = str(card_data["title"])
		name_lbl.add_theme_font_size_override("font_size", 20)
		name_lbl.modulate = Color(1.0, 1.0, 1.0)
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var desc_lbl := Label.new()
		desc_lbl.text = str(card_data["desc"])
		desc_lbl.add_theme_font_size_override("font_size", 15)
		desc_lbl.modulate = Color(0.85, 0.9, 0.95)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		text_vbox.add_child(rarity_lbl)
		text_vbox.add_child(name_lbl)
		text_vbox.add_child(desc_lbl)

		var choose_btn := Button.new()
		choose_btn.custom_minimum_size = Vector2(120, 56)
		choose_btn.text = "ELEGIR\nCOMODÍN"
		choose_btn.add_theme_font_size_override("font_size", 14)

		var captured_card: Dictionary = card_data
		choose_btn.pressed.connect(func():
			_on_card_selected(captured_card)
		)

		hbox.add_child(icon_lbl)
		hbox.add_child(text_vbox)
		hbox.add_child(choose_btn)

		card_panel.add_child(hbox)
		cards_container.add_child(card_panel)

func _on_card_selected(card_data: Dictionary) -> void:
	SoundManager.play_victory()
	var effect_value: Variant = card_data["effect_value"] if card_data.has("effect_value") else card_data["effects"]
	StatsManager.apply_card_upgrade(
		card_data["id"],
		card_data["effect_type"],
		effect_value,
		card_data["title"]
	)
	visible = false
	emit_signal("card_chosen", current_completed_order)
