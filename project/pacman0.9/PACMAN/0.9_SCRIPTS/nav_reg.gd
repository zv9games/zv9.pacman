extends NavigationRegion2D

signal online

@onready var gamestate = $"/root/BINARY/GAMESTATE"  # Adjust the path to your game manager or main node

func _ready():
	var timer = Timer.new()
	timer.wait_time = 0.5  # Adjust the delay as needed
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(timer)
	timer.start()

func _emit_online_signal():
	emit_signal("online", self.name)
