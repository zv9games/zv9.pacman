extends PopupPanel

signal option_selected

@onready var yes_button = $YesButton
@onready var no_button = $NoButton


func _ready():
	yes_button.connect("pressed", Callable(self, "_on_yes_button_pressed"))
	no_button.connect("pressed", Callable(self, "_on_no_button_pressed"))
	

func _on_yes_button_pressed():
	emit_signal("option_selected", "yes")
	hide()

func _on_no_button_pressed():
	emit_signal("option_selected", "no")
	hide()

func _on_skip_button_pressed():
	emit_signal("option_selected", "skip")
	hide()
