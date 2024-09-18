extends TileMapLayer

signal new_high_score

@export var max_high_scores = 5
@export var high_score_file_path = "user://high_scores.save"

var high_scores = []

@onready var input_box = $InputBox  # Assuming you have an InputBox node for initials input
@onready var display_board = $DisplayBoard  # Assuming you have a DisplayBoard node for displaying high scores

func _ready():
	load_high_scores()
	display_high_scores()
	connect("new_high_score", Callable(self, "_on_new_high_score"))

func load_high_scores():
	var file = FileAccess.open(high_score_file_path, FileAccess.READ)
	if file:
		high_scores = file.get_var([])  # Load high scores or initialize with an empty array
		file.close()
	else:
		print("Failed to open high score file for reading.")

func save_high_scores():
	var file = FileAccess.open(high_score_file_path, FileAccess.WRITE)
	if file:
		file.store_var(high_scores)
		file.close()
	else:
		print("Failed to open high score file for writing.")

func add_high_score(score, initials):
	high_scores.append({"score": score, "initials": initials})
	high_scores.sort_custom(self, "_sort_scores")
	if high_scores.size() > max_high_scores:
		high_scores.pop_back()
	save_high_scores()
	display_high_scores()

func _sort_scores(a, b):
	return b["score"] - a["score"]

func display_high_scores():
	display_board.clear()
	for i in range(min(high_scores.size(), max_high_scores)):
		var entry = high_scores[i]
		display_board.add_entry(entry["initials"], entry["score"])

func check_new_high_score(score):
	if high_scores.size() < max_high_scores or score > high_scores[-1]["score"]:
		emit_signal("new_high_score", score)

func _on_new_high_score(score):
	input_box.show()
	input_box.connect("text_entered", self, "_on_initials_entered", [score])

func _on_initials_entered(initials, score):
	input_box.hide()
	add_high_score(score, initials)
