extends Button

signal initialized

var binary: Node
var pacman: Node
var blinky: Node
var pinky: Node
var inky: Node
var clyde: Node
var tilemap: Node

func _ready():
	binary = get_node("/root/BINARY")
	pacman = get_node("/root/BINARY/GAMEPLAY/CHARACTERS/PAC_BODY")  # Adjust the path to your PacMan node
	blinky = get_node("/root/BINARY/GAMEPLAY/CHARACTERS/GHOSTS/BLINKY_BODY")  # Adjust the path to your first ghost node
	pinky = get_node("/root/BINARY/GAMEPLAY/CHARACTERS/GHOSTS/PINKY_BODY")
	inky = get_node("/root/BINARY/GAMEPLAY/CHARACTERS/GHOSTS/INKY_BODY")
	clyde = get_node("/root/BINARY/GAMEPLAY/CHARACTERS/GHOSTS/CLYDE_BODY")
	tilemap = get_node("/root/BINARY/GAMEPLAY/MAP/TILEMAP")
	# Set Pac-Man and each ghost to be initially invisible
	pacman.visible = false
	blinky.visible = false
	pinky.visible = false
	inky.visible = false
	clyde.visible = false
	tilemap.visible = false

	self.connect("pressed", Callable(self, "_on_button_up"))
	emit_signal("initialized", self.name)

func _on_button_up():
	self.hide()  # Hide the button
	pacman.visible = true  # Make Pac-Man visible
	blinky.visible = true  # Make the first ghost visible
	pinky.visible = true  # Make the second ghost visible
	inky.visible = true  # Make the third ghost visible
	clyde.visible = true  # Make the fourth ghost visible
	tilemap.visible = true
	binary.start_game()  # Start the game
