extends Node

@export var world : SonicBlockWorld

func _network_process(_input: Dictionary) -> void:
	world._simulate()
