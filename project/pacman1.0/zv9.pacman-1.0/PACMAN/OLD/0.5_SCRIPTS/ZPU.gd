extends Node

var has_printed = false


func _init():
	print("ZPU Init")

func _enter_tree():
	print("ZPU Enter Tree")

func _ready():
	print("ZPU Ready")

func _process(delta):
	if not has_printed:
		print("ZPU Process")
		has_printed = true

func _exit_tree():
	print("ZPU Exit Tree")
