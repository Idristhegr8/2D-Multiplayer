extends Node

const SAVE_DATA_PATH = "user://Save.json"

var DEFAULT_SAVE_DATA: Dictionary = {
	First_run = true,
	OS_unique_id = OS.get_unique_id(),
	wins = 0
}

func save(data) -> void:
	var save_file = File.new()
	save_file.open_encrypted_with_pass(SAVE_DATA_PATH, File.WRITE, "its78652")
	save_file.store_line(to_json(data))
	save_file.close()

func load_data():
	var save_file = File.new()
	if not save_file.file_exists(SAVE_DATA_PATH):
		return DEFAULT_SAVE_DATA

	else:
		save_file.open_encrypted_with_pass(SAVE_DATA_PATH, File.READ, "its78652")
		var data = parse_json(save_file.get_as_text())
		save_file.close()
		return data
