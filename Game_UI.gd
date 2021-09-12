extends CanvasLayer

onready var win_timer = $Control/Winner/Win_timer
onready var winner = $Control/Winner

signal add_win

var signal_emitted: bool = false
var data: Dictionary

func _ready() -> void:
# warning-ignore:return_value_discarded
	connect("add_win", self, "add_win")

	data = SaveAndLoad.load_data()

	winner.hide()

func _process(_delta: float) -> void:
	if Global.alive_players.size() == 1 and get_tree().has_network_peer():
		if Global.alive_players[0].name == str(get_tree().get_network_unique_id()):
			winner.show()

			if not signal_emitted:
				emit_signal("add_win")
				signal_emitted = true
				data.wins = Global.wins

			SaveAndLoad.save(data)
		
		if win_timer.time_left <= 0:
			win_timer.start()

func add_win():
	Global.wins += 0.5
