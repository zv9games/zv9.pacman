extends Node

signal online
signal start_sound_finished

enum States { CHASE, SCATTER, FRIGHTENED, INITIAL, LOADING, PAUSE }

@onready var siren1 = $"/root/BINARY/GAME/SOUNDBANK/SIREN1"
@onready var siren2 = $"/root/BINARY/GAME/SOUNDBANK/SIREN2"
@onready var siren3 = $"/root/BINARY/GAME/SOUNDBANK/SIREN3"
@onready var siren4 = $"/root/BINARY/GAME/SOUNDBANK/SIREN4"
@onready var credit = $"/root/BINARY/GAME/SOUNDBANK/CREDIT"
@onready var intermission = $"/root/BINARY/GAME/SOUNDBANK/INTERMISSION"
@onready var extend = $"/root/BINARY/GAME/SOUNDBANK/EXTEND"
@onready var start = $"/root/BINARY/GAME/SOUNDBANK/START"
@onready var fright = $"/root/BINARY/GAME/SOUNDBANK/FRIGHT"
@onready var eat1 = $"/root/BINARY/GAME/SOUNDBANK/EAT1"
@onready var eat2 = $"/root/BINARY/GAME/SOUNDBANK/EAT2"
@onready var death1 = $"/root/BINARY/GAME/SOUNDBANK/DEATH1"
@onready var death2 = $"/root/BINARY/GAME/SOUNDBANK/DEATH2"
@onready var eat_fruit = $"/root/BINARY/GAME/SOUNDBANK/EAT_FRUIT"
@onready var eat_ghost = $"/root/BINARY/GAME/SOUNDBANK/EAT_GHOST"
@onready var eyes = $"/root/BINARY/GAME/SOUNDBANK/EYES"
@onready var gameboard = $/root/BINARY/LEVELS/ORIGINAL/MAP/GAMEBOARD
@onready var sirentimer = $/root/BINARY/GAME/SOUNDBANK/SIRENTIMER
@onready var pacman = $/root/BINARY/LEVELS/ORIGINAL/CHARACTERS/PACMAN
@onready var blinky = $/root/BINARY/LEVELS/ORIGINAL/CHARACTERS/BLINKY
@onready var pinky = $/root/BINARY/LEVELS/ORIGINAL/CHARACTERS/PINKY
@onready var inky = $/root/BINARY/LEVELS/ORIGINAL/CHARACTERS/INKY
@onready var clyde = $/root/BINARY/LEVELS/ORIGINAL/CHARACTERS/CLYDE

@onready var zpu5 = get_node("/root/BINARY/GAME/ZPU")
@onready var gamestate = $"/root/BINARY/GAME/GAMESTATE"

func _ready():
	var timer = Timer.new()
	timer.wait_time = 0.5  # Adjust the delay as needed
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_emit_online_signal"))
	add_child(timer)
	timer.start()
	
func _emit_online_signal():
	emit_signal("online", self.name)
	connect_sounds()

func connect_sounds():
	siren1.connect("finished", Callable(self, "_on_siren1_sound_finished"))
	siren2.connect("finished", Callable(self, "_on_siren2_sound_finished"))
	siren3.connect("finished", Callable(self, "_on_siren3_sound_finished"))
	siren4.connect("finished", Callable(self, "_on_siren4_sound_finished"))
	fright.connect("finished", Callable(self, "_on_fright_sound_finished"))
	start.connect("finished", Callable(self, "_on_start_sound_finished"))
	
var sound_paths = {
	"SIREN1": "/root/BINARY/GAME/SOUNDBANK/SIREN1",
	"SIREN2": "/root/BINARY/GAME/SOUNDBANK/SIREN2",
	"SIREN3": "/root/BINARY/GAME/SOUNDBANK/SIREN3",
	"SIREN4": "/root/BINARY/GAME/SOUNDBANK/SIREN4",
	"CREDIT": "/root/BINARY/GAME/SOUNDBANK/CREDIT",
	"INTERMISSION": "/root/BINARY/GAME/SOUNDBANK/INTERMISSION",
	"EXTEND": "/root/BINARY/GAME/SOUNDBANK/EXTEND",
	"START": "/root/BINARY/GAME/SOUNDBANK/START",
	"FRIGHT": "/root/BINARY/GAME/SOUNDBANK/FRIGHT",
	"EAT1": "/root/BINARY/GAME/SOUNDBANK/EAT1",
	"EAT2": "/root/BINARY/GAME/SOUNDBANK/EAT2",
	"DEATH1": "/root/BINARY/GAME/SOUNDBANK/DEATH1",
	"DEATH2": "/root/BINARY/GAME/SOUNDBANK/DEATH2",
	"EAT_FRUIT": "/root/BINARY/GAME/SOUNDBANK/EAT_FRUIT",
	"EAT_GHOST": "/root/BINARY/GAME/SOUNDBANK/EAT_GHOST",
	"EYES": "/root/BINARY/GAME/SOUNDBANK/EYES"
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
	for sound in $"/root/BINARY/GAME/SOUNDBANK".get_children():
		if sound is AudioStreamPlayer or sound is AudioStreamPlayer2D:
			sound.stop()
	
func stop_sound_timers():
	for timer in $"/root/BINARY/GAME/SOUNDBANK".get_children():
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
