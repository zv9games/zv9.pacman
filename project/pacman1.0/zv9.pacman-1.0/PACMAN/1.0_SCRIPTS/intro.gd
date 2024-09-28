extends TileMapLayer

signal online

func _ready():
	var timer = Timer.new()
	timer.wait_time = 0.5  # Adjust the delay as needed
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(timer)
	timer.start()
	launch_intro()

func _emit_online_signal():
	emit_signal("online", self.name)
	
########################################################################


signal intro_over

@onready var introtimer = $/root/BINARY/ZPU/TIMERS/INTROTIMER
@onready var zv9: Sprite2D = $/root/BINARY/GAME/INTRO/ZV9
@onready var splittwo: Sprite2D = $/root/BINARY/GAME/INTRO/SPLITTWO
@onready var namco: Sprite2D = $/root/BINARY/GAME/INTRO/NAMCO
@onready var loading = $/root/BINARY/GAME/LOADING
@onready var levelend = $/root/BINARY/GAME/ORIGINAL/LEVELEND
@onready var startmenu = $/root/BINARY/GAME/STARTMENU

func launch_intro():
	# Ensure all sprites are initially invisible
	zv9.visible = false
	splittwo.visible = false
	namco.visible = false
	
	# Set initial alpha to 0
	zv9.modulate.a = 0.0
	splittwo.modulate.a = 0.0
	namco.modulate.a = 0.0
	start_intro()

func start_intro():
	loading.visible = false
	levelend.visible = false
	# Start the fade-in and fade-out sequence
	fade_in_out(namco, 0.0, 0.5)

func fade_in_out(sprite: Sprite2D, delay: float, duration: float):
	sprite.visible = true
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5).set_delay(delay).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(duration)
	tween.tween_property(sprite, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.connect("finished", Callable(self, "_on_fade_out_complete").bind(sprite))

func _on_fade_out_complete(sprite: Sprite2D):
	sprite.visible = false
	if sprite == namco:
		fade_in_out(zv9, 0.0, 0.5)
	elif sprite == zv9:
		fade_in_out(splittwo, 0.0, 0.5)
	elif sprite == splittwo:
		_on_intro_complete()

func _on_intro_complete():
	# Hide intro and show loading screen
	self.visible = false
	startmenu.visible = true
	loading.visible = true
	emit_signal("intro_over")
