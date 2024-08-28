extends Node

signal online
signal start_sound_finished

enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, PRE_GAME }

@onready var gamestate = $"/root/BINARY/GAMESTATE"

func _ready():
	var timer = Timer.new()
	timer.wait_time = 0.2  # Adjust the delay as needed
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(timer)
	timer.start()
	siren1.connect("finished", Callable(self, "_on_siren1_finished"))
	fright.connect("finished", Callable(self, "_on_fright_finished"))
	start.connect("finished", Callable(self, "_on_start_finished"))
	
	
func _emit_online_signal():
	emit_signal("online", self.name)
	
@onready var siren1 = $"/root/BINARY/SOUNDBANK/SIREN1"
@onready var siren2 = $"/root/BINARY/SOUNDBANK/SIREN2"
@onready var siren3 = $"/root/BINARY/SOUNDBANK/SIREN3"
@onready var siren4 = $"/root/BINARY/SOUNDBANK/SIREN4"
@onready var credit = $"/root/BINARY/SOUNDBANK/CREDIT"
@onready var intermission = $"/root/BINARY/SOUNDBANK/INTERMISSION"
@onready var extend = $"/root/BINARY/SOUNDBANK/EXTEND"
@onready var start = $"/root/BINARY/SOUNDBANK/START"
@onready var fright = $"/root/BINARY/SOUNDBANK/FRIGHT"
@onready var eat1 = $"/root/BINARY/SOUNDBANK/EAT1"
@onready var eat2 = $"/root/BINARY/SOUNDBANK/EAT2"
@onready var death1 = $"/root/BINARY/SOUNDBANK/DEATH1"
@onready var death2 = $"/root/BINARY/SOUNDBANK/DEATH2"
@onready var eat_fruit = $"/root/BINARY/SOUNDBANK/EAT_FRUIT"
@onready var eat_ghost = $"/root/BINARY/SOUNDBANK/EAT_GHOST"
@onready var eyes = $"/root/BINARY/SOUNDBANK/EYES"
@onready var gameboard = $/root/BINARY/ORIGINAL/MAP/GAMEBOARD
@onready var sirentimer = $/root/BINARY/SOUNDBANK/SIRENTIMER
@onready var pacman = $/root/BINARY/ORIGINAL/CHARACTERS/PACMAN
@onready var blinky = $/root/BINARY/ORIGINAL/CHARACTERS/BLINKY
@onready var pinky = $/root/BINARY/ORIGINAL/CHARACTERS/PINKY
@onready var inky = $/root/BINARY/ORIGINAL/CHARACTERS/INKY
@onready var clyde = $/root/BINARY/ORIGINAL/CHARACTERS/CLYDE

@onready var zpu5 = get_node("/root/BINARY/ZPU")

# Dictionary to map sound names to node paths
var sound_paths = {
	"SIREN1": "/root/BINARY/SOUNDBANK/SIREN1",
	"SIREN2": "/root/BINARY/SOUNDBANK/SIREN2",
	"SIREN3": "/root/BINARY/SOUNDBANK/SIREN3",
	"SIREN4": "/root/BINARY/SOUNDBANK/SIREN4",
	"CREDIT": "/root/BINARY/SOUNDBANK/CREDIT",
	"INTERMISSION": "/root/BINARY/SOUNDBANK/INTERMISSION",
	"EXTEND": "/root/BINARY/SOUNDBANK/EXTEND",
	"START": "/root/BINARY/SOUNDBANK/START",
	"FRIGHT": "/root/BINARY/SOUNDBANK/FRIGHT",
	"EAT1": "/root/BINARY/SOUNDBANK/EAT1",
	"EAT2": "/root/BINARY/SOUNDBANK/EAT2",
	"DEATH1": "/root/BINARY/SOUNDBANK/DEATH1",
	"DEATH2": "/root/BINARY/SOUNDBANK/DEATH2",
	"EAT_FRUIT": "/root/BINARY/SOUNDBANK/EAT_FRUIT",
	"EAT_GHOST": "/root/BINARY/SOUNDBANK/EAT_GHOST",
	"EYES": "/root/BINARY/SOUNDBANK/EYES"
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
	for sound in $"/root/BINARY/SOUNDBANK".get_children():
		if sound is AudioStreamPlayer or sound is AudioStreamPlayer2D:
			sound.stop()

func _on_frighttimer_timeout():
	play("FRIGHT")
	
func stop_sound_timers():
	for timer in $"/root/BINARY/SOUNDBANK".get_children():
		if timer is Timer:
			timer.stop()
			
func _on_start_finished():
	blinky.visible = true
	pinky.visible = true
	inky.visible = true
	clyde.visible = true
	pacman.set_freeze(false)
	gameboard.count_dots()
	gameboard.play_siren()
	gamestate.set_state(States.INITIAL)
