extends Label

sync func return_to_lobby():
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Network_setup.tscn")

func _on_Win_timer_timeout():
	get_parent().get_parent().get_parent().get_node("Game_UI").signal_emitted = false
	if get_tree().is_network_server():
		rpc("return_to_lobby")
