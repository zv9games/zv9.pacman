extends Camera2D

signal swipe_detected(direction: Vector2)

var swipe_start_position = Vector2.ZERO
var swipe_end_position = Vector2.ZERO
var swiping = false
var swipe_threshold = 20  # Minimum distance for a swipe to be recognized

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			swiping = true
			swipe_start_position = event.position
		else:
			swiping = false
			swipe_end_position = event.position
			handle_swipe()
	elif event is InputEventScreenDrag:
		if swiping:
			swipe_end_position = event.position

func handle_swipe():
	var swipe_vector = swipe_end_position - swipe_start_position
	if swipe_vector.length() >= swipe_threshold:
		if abs(swipe_vector.x) > abs(swipe_vector.y):
			if swipe_vector.x > 0:
				emit_signal("swipe_detected", Vector2.RIGHT)
				print("swipe right")
			else:
				emit_signal("swipe_detected", Vector2.LEFT)
				print("swipe left")
		else:
			if swipe_vector.y > 0:
				emit_signal("swipe_detected", Vector2.DOWN)
				print("swipe down")
			else:
				emit_signal("swipe_detected", Vector2.UP)
				print("swipe up")
