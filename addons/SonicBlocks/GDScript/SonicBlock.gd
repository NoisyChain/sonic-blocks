@tool
extends Node
class_name SonicBlock

@export var graphics : Node3D

@export var _id : int
@export var is_active : bool
@export var is_static : bool
@export var is_character : bool
@export var is_trigger : bool
@export var is_right_side : bool = true
@export var box_position : Vector3i
@export var box_offset : Vector3i
@export var box_extents : Vector3i
@export var box_velocity : Vector3i
@export var generate_collision_events : bool
@export var preview_color : Color = Color()
@export var hurtboxes : Array[SonicHitbox]
@export var hitboxes : Array[SonicHitbox]
@export var draw_debug_shapes : bool

var FLAG_RIGHT = 1 << 0 #1
var FLAG_LEFT = 1 << 1 #2
var FLAG_FORWARD = 1 << 2 #4
var FLAG_BACK = 1 << 3 #8
var FLAG_UP = 1 << 4 #16
var FLAG_DOWN = 1 << 5 #32

#@export_flags("RIGHT", "LEFT", "FORWARD", "BACK", "UP", "DOWN") 
var collision_flags : int = 0

#initial setup
func _create(id : int) -> void:
	_id = id
	if hurtboxes.size() > 0:
		for hurt in hurtboxes:
			hurt.parent = self
	if hitboxes.size() > 0:
		for hit in hitboxes:
			hit.parent = self

#render process
func _process(delta: float) -> void:
	if graphics != null:
		graphics.global_position.x = box_position.x / float(1000)
		graphics.global_position.y = box_position.y / float(1000)
		graphics.global_position.z = box_position.z / float(1000)
	
	#debug draws
	draw_collision_box()
	draw_hurtboxes()
	draw_hitboxes()

func draw_collision_box() -> void:
	if not draw_debug_shapes: return
	var offset = box_offset / float(1000)
	if not is_right_side: offset.x *= -1
	var size = box_extents / float(1000)
	DebugDraw3D.draw_box(graphics.global_position + offset, Quaternion.IDENTITY, size * 2, preview_color, true)

func draw_hurtboxes() -> void:
	if not draw_debug_shapes: return
	for hurt in hurtboxes:
		if hurt.box_extents == Vector3i.ZERO: continue
		var offset = hurt.box_offset / float(1000)
		if not is_right_side: offset.x *= -1
		var size = hurt.box_extents / float(1000)
		DebugDraw3D.draw_box(graphics.global_position + offset, Quaternion.IDENTITY, size * 2, hurt.preview_color, true)

func draw_hitboxes() -> void:
	if not draw_debug_shapes: return
	for hit in hitboxes:
		if hit.box_extents == Vector3i.ZERO: continue
		var offset = hit.box_offset / float(1000)
		if not is_right_side: offset.x *= -1
		var size = hit.box_extents / float(1000)
		DebugDraw3D.draw_box(graphics.global_position + offset, Quaternion.IDENTITY, size * 2, hit.preview_color, true)

func set_position(pos : Vector3i) -> void:
	if is_static: return
	box_position = pos

func set_velocity(vel : Vector3i) -> void:
	if is_static: return
	box_velocity = vel

func set_offset(ofs : Vector3i) -> void:
	if is_static: return
	box_offset = ofs

func set_extents(ext : Vector3i) -> void:
	if is_static: return
	box_extents = ext

#executed every frame in SonicBlockWorld
func move(steps : int) -> void:
	if is_static: return
	if box_velocity == Vector3i.ZERO: return
	box_position += box_velocity / steps

#used to resolve collisions, no use for anything else
func resolve(depth : Vector3i):
	box_position -= depth

func get_collision_flags(normal : Vector3i) -> void:
	if normal.x > 0:
		collision_flags |= FLAG_RIGHT
	if normal.x < 0:
		collision_flags |= FLAG_LEFT
	if normal.z < 0:
		collision_flags |= FLAG_FORWARD
	if normal.z > 0:
		collision_flags |= FLAG_BACK
	if normal.y > 0:
		collision_flags |= FLAG_UP
	if normal.y < 0:
		collision_flags |= FLAG_DOWN

func ckeck_collision_flags(flag : int) -> bool:
	return collision_flags & flag

func get_sided_vector() -> Vector3i:
	if not is_right_side: return Vector3i(-1, 1, 1)
	return Vector3i(1, 1, 1)

#body collision event
func collision_event(target : SonicBlock, point : Vector3i) -> void:
	#print(collision_flags)
	pass

#hitboxes collision event
func hitbox_event(box : SonicHitbox, point : Vector3i) -> void:
	#print(box.parent.name + ", " + box.name)
	pass
