extends Node

var Os = OS.get_name()
var player_master = null
var ui = null

var wins: float = 0

var alive_players: Array = []

var data = SaveAndLoad.load_data()

func _ready():
	yield(get_tree(), "idle_frame")
#	var file = SaveAndLoad.DEFAULT_SAVE_DATA
#	SaveAndLoad.save(file)

	if data.First_run:
		data.OS_unique_id = OS.get_unique_id()
		data.First_run = false
		SaveAndLoad.save(data)

	if data.OS_unique_id != str(OS.get_unique_id()):
		get_tree().quit()
	print(Os)

func instance_node_at_location(node: Object, parent: Object, location: Vector2) -> Object:
	var node_instance = instance_node(node, parent)
	node_instance.global_position = location
	return node_instance

func instance_node(node: Object, parent: Object) -> Object:
	var node_instance = node.instance()
	parent.add_child(node_instance)
	return node_instance
