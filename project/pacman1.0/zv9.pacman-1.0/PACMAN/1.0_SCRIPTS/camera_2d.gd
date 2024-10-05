extends Camera2D

signal online

func _ready():
	var timer = Timer.new()
	timer.wait_time = 0.5  # Adjust the delay as needed
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(timer)
	timer.start()
	start_camera()

func _emit_online_signal():
	emit_signal("online", self.name)
	
########################################################################

signal swipe_detected(direction: Vector2)

var swipe_start_position = Vector2.ZERO
var swipe_end_position = Vector2.ZERO
var swiping = false
var swipe_threshold = 20  # Minimum distance for a swipe to be recognized

func start_camera():
	pass

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
				
			else:
				emit_signal("swipe_detected", Vector2.LEFT)
				
		else:
			if swipe_vector.y > 0:
				emit_signal("swipe_detected", Vector2.DOWN)
				
			else:
				emit_signal("swipe_detected", Vector2.UP)
				
