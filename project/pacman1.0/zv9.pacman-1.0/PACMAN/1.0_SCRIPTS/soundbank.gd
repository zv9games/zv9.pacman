extends Node

signal online

func _ready():
	var timer = Timer.new()
	timer.wait_time = 0.5  # Adjust the delay as needed
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(timer)
	timer.start()
	start_soundbank()

func _emit_online_signal():
	emit_signal("online", self.name)

##########################################################################


signal start_sound_finished

enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, LOADING, PAUSE }

@onready var siren1 = $"/root/BINARY/ZPU/SOUNDBANK/SIREN1"
@onready var siren2 = $"/root/BINARY/ZPU/SOUNDBANK/SIREN2"
@onready var siren3 = $"/root/BINARY/ZPU/SOUNDBANK/SIREN3"
@onready var siren4 = $"/root/BINARY/ZPU/SOUNDBANK/SIREN4"
@onready var credit = $"/root/BINARY/ZPU/SOUNDBANK/CREDIT"
@onready var intermission = $"/root/BINARY/ZPU/SOUNDBANK/INTERMISSION"
@onready var extend = $"/root/BINARY/ZPU/SOUNDBANK/EXTEND"
@onready var start = $"/root/BINARY/ZPU/SOUNDBANK/START"
@onready var fright = $"/root/BINARY/ZPU/SOUNDBANK/FRIGHT"
@onready var eat1 = $"/root/BINARY/ZPU/SOUNDBANK/EAT1"
@onready var eat2 = $"/root/BINARY/ZPU/SOUNDBANK/EAT2"
@onready var death1 = $"/root/BINARY/ZPU/SOUNDBANK/DEATH1"
@onready var death2 = $"/root/BINARY/ZPU/SOUNDBANK/DEATH2"
@onready var eat_fruit = $"/root/BINARY/ZPU/SOUNDBANK/EAT_FRUIT"
@onready var eat_ghost = $"/root/BINARY/ZPU/SOUNDBANK/EAT_GHOST"
@onready var eyes = $"/root/BINARY/ZPU/SOUNDBANK/EYES"
@onready var gameboard = $/root/BINARY/GAME/ORIGINAL/TILEMAPLAYER
@onready var sirentimer = $/root/BINARY/ZPU/SOUNDBANK/SIRENTIMER
@onready var pacman = $/root/BINARY/GAME/CHARACTERS/PACMAN
@onready var blinky = $/root/BINARY/GAME/CHARACTERS/BLINKY
@onready var pinky = $/root/BINARY/GAME/CHARACTERS/PINKY
@onready var inky = $/root/BINARY/GAME/CHARACTERS/INKY
@onready var clyde = $/root/BINARY/GAME/CHARACTERS/CLYDE

@onready var zpu5 = get_node("/root/BINARY/ZPU")
@onready var gamestate = $"/root/BINARY/ZPU/GAMESTATE"

	
func start_soundbank():
	connect_sounds()

func connect_sounds():
	siren1.connect("finished", Callable(self, "_on_siren1_sound_finished"))
	siren2.connect("finished", Callable(self, "_on_siren2_sound_finished"))
	siren3.connect("finished", Callable(self, "_on_siren3_sound_finished"))
	siren4.connect("finished", Callable(self, "_on_siren4_sound_finished"))
	fright.connect("finished", Callable(self, "_on_fright_sound_finished"))
	start.connect("finished", Callable(self, "_on_start_sound_finished"))
	
var sound_paths = {
	"SIREN1": "/root/BINARY/ZPU/SOUNDBANK/SIREN1",
	"SIREN2": "/root/BINARY/ZPU/SOUNDBANK/SIREN2",
	"SIREN3": "/root/BINARY/ZPU/SOUNDBANK/SIREN3",
	"SIREN4": "/root/BINARY/ZPU/SOUNDBANK/SIREN4",
	"CREDIT": "/root/BINARY/ZPU/SOUNDBANK/CREDIT",
	"INTERMISSION": "/root/BINARY/ZPU/SOUNDBANK/INTERMISSION",
	"EXTEND": "/root/BINARY/ZPU/SOUNDBANK/EXTEND",
	"START": "/root/BINARY/ZPU/SOUNDBANK/START",
	"FRIGHT": "/root/BINARY/ZPU/SOUNDBANK/FRIGHT",
	"EAT1": "/root/BINARY/ZPU/SOUNDBANK/EAT1",
	"EAT2": "/root/BINARY/ZPU/SOUNDBANK/EAT2",
	"DEATH1": "/root/BINARY/ZPU/SOUNDBANK/DEATH1",
	"DEATH2": "/root/BINARY/ZPU/SOUNDBANK/DEATH2",
	"EAT_FRUIT": "/root/BINARY/ZPU/SOUNDBANK/EAT_FRUIT",
	"EAT_GHOST": "/root/BINARY/ZPU/SOUNDBANK/EAT_GHOST",
	"EYES": "/root/BINARY/ZPU/SOUNDBANK/EYES"
}

func play(sound_name):
	if sound_name in sound_paths:
		var sound = get_node(sound_paths[sound_name])
		if sound:
			sound.play()
		else:
			print("Sound not found: " + sound_name)
	else:
		print("Invalid sound name: " + sound_name)

func stop(sound_name):
	if sound_name in sound_paths:
		var sound = get_node(sound_paths[sound_name])
		if sound:
			sound.stop()

func stop_all_sounds():
	for sound in $"/root/BINARY/ZPU/SOUNDBANK".get_children():
		if sound is AudioStreamPlayer or sound is AudioStreamPlayer2D:
			sound.stop()
	
func stop_sound_timers():
	for timer in $"/root/BINARY/ZPU/SOUNDBANK".get_children():
		if timer is Timer:
			timer.stop()

func play_siren():
	sirentimer.start()
	var dots_left = gameboard.get_dots_left()
	if dots_left <= 30:
		play("SIREN4")
	elif dots_left <= 100:
		play("SIREN3")
	elif dots_left <= 170:
		play("SIREN2")
	elif dots_left <= 255:
		play("SIREN1")

func _on_start_sound_finished():
	print("start sound finished signal")
	emit_signal("start_sound_finished")

func _on_siren1_sound_finished():
	play_siren()

func _on_siren2_sound_finished():
	play_siren()
	
func _on_siren3_sound_finished():
	play_siren()
	
func _on_siren4_sound_finished():
	play_siren()
	
func _on_fright_sound_finished():
	play("FRIGHT")
