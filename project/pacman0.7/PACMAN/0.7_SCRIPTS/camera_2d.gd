extends Node2D

signal swipe_detected(direction: Vector2)

var start_position = Vector2.ZERO
var swipe_threshold = 50  # Minimum distance for a swipe to be recognized
var swipe_time = 0.3  # Maximum time for a swipe to be recognized
var swipe_timer = 0.0
var is_swiping = false

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			start_position = event.position
			swipe_timer = 0.0
			is_swiping = true
			print("Touch started at: ", start_position)
		else:
			if is_swiping:
				var end_position = event.position
				var swipe_vector = end_position - start_position
				print("Touch ended at: ", end_position, " Swipe vector: ", swipe_vector)
				if swipe_vector.length() >= swipe_threshold and swipe_timer <= swipe_time:
					emit_signal("swipe_detected", swipe_vector.normalized())
					print("Swipe detected, direction: ", swipe_vector.normalized())
				is_swiping = false
	elif event is InputEventScreenDrag:
		if is_swiping:
			swipe_timer += event.relative.length() / swipe_threshold
			print("Dragging, swipe timer: ", swipe_timer)

func _process(delta):
	if is_swiping:
		swipe_timer += delta
