@tool
extends SonicBlock
class_name PlayerExample

@export var speed : int = 400
@export var jump_speed : int = 400
@export var gravity : int = 400
@export var camera : Camera3D

var input_prefix := "player1_"

func setup() -> void:
	camera.visible = false

func _get_local_input() -> Dictionary:
	var jump = Input.is_action_just_pressed(input_prefix + "bomb")
	var direction = Vector2()
	direction.x = Input.get_action_strength(input_prefix + "right") - Input.get_action_strength(input_prefix + "left")
	direction.y = Input.get_action_strength(input_prefix + "up") - Input.get_action_strength(input_prefix + "down")
	direction = direction.limit_length()
	var int_direction = Vector2i(direction * 100)
	
	var input := {}
	input["direction"] = int_direction
	input["jump"] = jump
	
	return input

func _predict_remote_input(previous_input: Dictionary, ticks_since_real_input: int) -> Dictionary:
	var input = previous_input.duplicate()
	return input

func _network_process(input: Dictionary) -> void:
	var i_direction = input.get("direction", Vector2i.ZERO)
	var i_jump = input.get("jump", false)
	
	if (is_on_ground()):
		box_velocity.y = -100
		box_velocity.x = (i_direction.x * speed) / 100
		box_velocity.z = (-i_direction.y * speed) / 100
		if i_jump:
			box_velocity.y = jump_speed
	else:
		box_velocity.y -= gravity

#surface checks use collision flags
func is_on_ground() -> bool:
	return ckeck_collision_flags(FLAG_DOWN)

func is_on_wall() -> bool:
	return ckeck_collision_flags(FLAG_RIGHT) or ckeck_collision_flags(FLAG_LEFT) or ckeck_collision_flags(FLAG_FORWARD) or ckeck_collision_flags(FLAG_BACK)

func is_on_ceiling() -> bool:
	return ckeck_collision_flags(FLAG_UP)

func _save_state() -> Dictionary:
	return {
		position = box_position,
		velocity = box_velocity,
		colflags = collision_flags,
		side = is_right_side,
	}

func _load_state(state: Dictionary) -> void:
	box_position = state['position']
	box_velocity = state['velocity']
	collision_flags = state['colflags']
	is_right_side = state['side']

func _interpolate_state(old_state: Dictionary, new_state: Dictionary, weight: float) -> void:
	#box_position = lerp(old_state['position'], new_state['position'], weight)
	pass
