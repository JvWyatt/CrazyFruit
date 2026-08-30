extends ScrollContainer
## Adds finger-drag scrolling so touch users can swipe shop/stats lists directly.
# Puramente de interfaz (scroll táctil), sin relación con el balance del juego.

var _dragging: bool = false
var _last_pos: Vector2 = Vector2.ZERO

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_dragging = event.pressed
		_last_pos = event.position
	elif event is InputEventScreenDrag and _dragging:
		var delta: Vector2 = event.position - _last_pos
		_last_pos = event.position
		scroll_horizontal -= int(delta.x)
		scroll_vertical -= int(delta.y)
		accept_event()
