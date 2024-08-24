extends TileMap

signal online

func _ready():

	# Create a timer with a 0.5-second delay
	var startup_timer = Timer.new()
	startup_timer.wait_time = 0.5
	startup_timer.one_shot = true
	startup_timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(startup_timer)
	startup_timer.start()

func _emit_online_signal():
	emit_signal("online", self.name)

#BREAK
