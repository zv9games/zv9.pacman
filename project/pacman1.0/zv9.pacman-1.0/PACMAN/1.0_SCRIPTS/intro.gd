extends TileMapLayer

signal online

func _ready():
	zv9.visible = false
	splittwo.visible = false
	namco.visible = false
	microsoft.visible = false
	tux.visible = false
	var timer = Timer.new()
	timer.wait_time = 0.5  # Adjust the delay as needed
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_emit_online_signal"))
	binary.connect("all_nodes_initialized", Callable(self, "launch_intro"))
	add_child(timer)
	timer.start()
	

func _emit_online_signal():
	emit_signal("online", self.name)
	
########################################################################


signal intro_over

@onready var introtimer = $/root/BINARY/ZPU/TIMERS/INTROTIMER
@onready var zv9: Sprite2D = $/root/BINARY/MENUS/INTRO/ZV9
@onready var splittwo: Sprite2D = $/root/BINARY/MENUS/INTRO/SPLITTWO
@onready var namco: Sprite2D = $/root/BINARY/MENUS/INTRO/NAMCO
@onready var loading = $/root/BINARY/MENUS/LOADING
@onready var levelend = $/root/BINARY/GAME/ORIGINAL/LEVELEND
@onready var startmenu = $/root/BINARY/MENUS/STARTMENU
@onready var microsoft = $/root/BINARY/MENUS/INTRO/MICROSOFT
@onready var tux = $/root/BINARY/MENUS/INTRO/TUX
@onready var binary = $/root/BINARY

func launch_intro():
	# Set initial alpha to 0
	zv9.modulate.a = 0.0
	splittwo.modulate.a = 0.0
	namco.modulate.a = 0.0
	tux.modulate.a = 0.0
	microsoft.modulate.a = 0.0
	start_intro()

func start_intro():
	loading.visible = false
	levelend.visible = false
	# Start the fade-in and fade-out sequence
	fade_in_out(tux, 0.0, 0.5)

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
	if sprite == tux:
		fade_in_out(namco, 0.0, 0.5)
	elif sprite == namco:
		fade_in_out(zv9, 0.0, 0.5)
	elif sprite == zv9:
		fade_in_out(microsoft, 0.0, 0.5)
	elif sprite == microsoft:
		fade_in_out(splittwo, 0.0, 0.5)
	elif sprite == splittwo:
		_on_intro_complete()

func _on_intro_complete():
	# Hide intro and show loading screen
	self.visible = false
	startmenu.visible = true
	loading.visible = true
	emit_signal("intro_over")
