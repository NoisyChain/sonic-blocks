extends Node
class_name SonicBlockWorld

var tickrate = ProjectSettings.get_setting("physics/common/physics_ticks_per_second")

@export var blocks : Array[SonicBlock]
@export var characters : Array[SonicBlock]

func _ready() -> void:
	for x in blocks.size():
		blocks[x]._create(x)
		if blocks[x].is_character:
			characters.append(blocks[x])
	#print(str(blocks.size()) + ", " + str(characters.size()))

func _simulate() -> void:
	for x in blocks:
		x.collision_flags = 0
		x.move(tickrate)
	#collision pass
	for x in blocks.size():
		if not blocks[x].is_active: continue #do not waste time checking inactive collisions
		if blocks[x].box_extents == Vector3i.ZERO: continue
		for y in blocks.size():
			if y <= x: continue #avoid repeating collisions
			if not blocks[y].is_active: continue #do not waste time checking inactive collisions
			if blocks[y].box_extents == Vector3i.ZERO: continue
			if blocks[x].is_static and blocks[y].is_static: continue #do not wast time checking collisions against static objects
			if blocks[x] != blocks[y] and bodies_overlap(blocks[x], blocks[y]):
				var normal = Vector3i()
				if blocks[x].is_character and blocks[y].is_character:
					normal = get_character_collision_normal(blocks[x], blocks[y])
				else:
					normal = get_collision_normal(blocks[x], blocks[y])
				var depth = normal * get_collision_depth(blocks[x], blocks[y])
				var point = get_contact_point(blocks[x], blocks[y])
				if not blocks[x].is_trigger and not blocks[y].is_trigger:
					if not blocks[x].is_character or blocks[x].is_static:
						blocks[y].resolve(-depth)
					elif not blocks[y].is_character or blocks[y].is_static:
						blocks[x].resolve(depth)
					else:
						blocks[x].resolve(depth / 2)
						blocks[y].resolve(-depth / 2)
				blocks[x].get_collision_flags(normal)
				blocks[y].get_collision_flags(-normal)
				if blocks[x].generate_collision_events:
					blocks[x].collision_event(blocks[y], point)
				if blocks[y].generate_collision_events:
					blocks[y].collision_event(blocks[x], point)
	#hitboxes pass
	for x in characters.size():
		if characters[x].hitboxes.size() == 0: continue  #do not try to do anything if there's no boxes to test with
		for y in characters.size():
			if x == y: continue #ignore same character
			if characters[y].hurtboxes.size() == 0: continue #do not try to do anything if there's no boxes to test against
			for hb_x in characters[x].hitboxes.size():
				if characters[x].hitboxes[hb_x].box_extents == Vector3i.ZERO: continue
				for hb_y in characters[y].hurtboxes.size():
					if characters[y].hurtboxes[hb_y].box_extents == Vector3i.ZERO: continue
					if hitboxes_overlap(characters[x].hitboxes[hb_x], characters[y].hurtboxes[hb_y]):
						var point = get_hitbox_contact_point(characters[x].hitboxes[hb_x], characters[y].hurtboxes[hb_y])
						if characters[x].generate_collision_events:
							characters[x].hitbox_event(characters[y].hurtboxes[hb_y], point)
			
func bodies_overlap(a : SonicBlock, b : SonicBlock) -> bool:
	var a_center = a.box_position + (a.box_offset * a.get_sided_vector())
	var b_center = b.box_position + (b.box_offset * b.get_sided_vector())
	var col_x = a_center.x - a.box_extents.x <= b_center.x + b.box_extents.x and a_center.x + a.box_extents.x >= b_center.x - b.box_extents.x
	var col_y = a_center.y - a.box_extents.y <= b_center.y + b.box_extents.y and a_center.y + a.box_extents.y >= b_center.y - b.box_extents.y
	var col_z = a_center.z - a.box_extents.z <= b_center.z + b.box_extents.z and a_center.z + a.box_extents.z >= b_center.z - b.box_extents.z
	return col_x and col_y and col_z

func hitboxes_overlap(a : SonicHitbox, b : SonicHitbox) -> bool:
	var a_center = a.parent.box_position + (a.box_offset * a.parent.get_sided_vector())
	var b_center = b.parent.box_position + (b.box_offset * b.parent.get_sided_vector())
	var col_x = a_center.x - a.box_extents.x <= b_center.x + b.box_extents.x and a_center.x + a.box_extents.x >= b_center.x - b.box_extents.x
	var col_y = a_center.y - a.box_extents.y <= b_center.y + b.box_extents.y and a_center.y + a.box_extents.y >= b_center.y - b.box_extents.y
	var col_z = a_center.z - a.box_extents.z <= b_center.z + b.box_extents.z and a_center.z + a.box_extents.z >= b_center.z - b.box_extents.z
	return col_x and col_y and col_z

func get_collision_normal(a : SonicBlock, b : SonicBlock) -> Vector3i:
	var final_normal = Vector3i()
	var a_center = a.box_position + (a.box_offset * a.get_sided_vector())
	var b_center = b.box_position + (b.box_offset * b.get_sided_vector())
	var length = b_center - a_center
	var extents_x = a.box_extents.x + b.box_extents.x
	var extents_y = a.box_extents.y + b.box_extents.y
	var extents_z = a.box_extents.z + b.box_extents.z
	if abs(length.x) + extents_y > abs(length.y) + extents_x or abs(length.z) + extents_y > abs(length.y) + extents_z:
		if abs(length.x) + extents_z > abs(length.z) + extents_x:
			if a_center.x < b_center.x:
				final_normal = Vector3i.RIGHT
			else:
				final_normal = Vector3i.LEFT
		else:
			if a_center.z < b_center.z:
				final_normal = Vector3i.BACK
			else:
				final_normal = Vector3i.FORWARD
	else:
		if a_center.y < b_center.y:
			final_normal = Vector3i.UP
		else:
			final_normal = Vector3i.DOWN
	return final_normal;

func get_character_collision_normal(a : SonicBlock, b : SonicBlock) -> Vector3i:
	var final_normal = Vector3i()
	var a_center = a.box_position + (a.box_offset * a.get_sided_vector())
	var b_center = b.box_position + (b.box_offset * b.get_sided_vector())
	var length = b_center - a_center
	var extents_x = a.box_extents.x + b.box_extents.x
	var extents_y = a.box_extents.y + b.box_extents.y
	var extents_z = a.box_extents.z + b.box_extents.z
	if abs(length.x) + extents_z >= abs(length.z) + extents_x:
		if a_center.x < b_center.x:
			final_normal = Vector3i.RIGHT
		elif a_center.x > b_center.x:
			final_normal = Vector3i.LEFT
		else:
			var side = 0
			if a.is_right_side: side = 1
			else: side = -1
			final_normal = Vector3i(side, 0, 0)
	else:
		if a_center.z < b_center.z:
			final_normal = Vector3i.BACK
		else:
			final_normal = Vector3i.FORWARD
	return final_normal;

func get_collision_depth(a : SonicBlock, b : SonicBlock) -> Vector3i:
	var a_center = a.box_position + (a.box_offset * a.get_sided_vector())
	var b_center = b.box_position + (b.box_offset * b.get_sided_vector())
	var length = b_center - a_center
	var depth_x = a.box_extents.x + b.box_extents.x
	var depth_y = a.box_extents.y + b.box_extents.y
	var depth_z = a.box_extents.z + b.box_extents.z
	depth_x -= abs(length.x)
	depth_y -= abs(length.y)
	depth_z -= abs(length.z)
	return Vector3i(depth_x, depth_y, depth_z)

func get_contact_point(a : SonicBlock, b : SonicBlock) -> Vector3i:
	var a_center = a.box_position + (a.box_offset * a.get_sided_vector())
	var b_center = b.box_position + (b.box_offset * b.get_sided_vector())
	var minPointX = min(a_center.x + a.box_extents.x, b_center.x + b.box_extents.x)
	var maxPointX = max(a_center.x - a.box_extents.x, b_center.x - b.box_extents.x)
	var minPointY = min(a_center.y + a.box_extents.y, b_center.y + b.box_extents.y)
	var maxPointY = max(a_center.y - a.box_extents.y, b_center.y - b.box_extents.y)
	var minPointZ = min(a_center.z + a.box_extents.z, b_center.z + b.box_extents.z)
	var maxPointZ = max(a_center.z - a.box_extents.z, b_center.z - b.box_extents.z)
	var median_x = (minPointX + maxPointX) / 2
	var median_y = (minPointY + maxPointY) / 2
	var median_z = (minPointZ + maxPointZ) / 2
	return Vector3i(median_x, median_y, median_z)

func get_hitbox_contact_point(a : SonicHitbox, b : SonicHitbox) -> Vector3i:
	var a_center = a.parent.box_position + (a.box_offset * a.parent.get_sided_vector())
	var b_center = b.parent.box_position + (b.box_offset * b.parent.get_sided_vector())
	var minPointX = min(a_center.x + a.box_extents.x, b_center.x + b.box_extents.x)
	var maxPointX = max(a_center.x - a.box_extents.x, b_center.x - b.box_extents.x)
	var minPointY = min(a_center.y + a.box_extents.y, b_center.y + b.box_extents.y)
	var maxPointY = max(a_center.y - a.box_extents.y, b_center.y - b.box_extents.y)
	var minPointZ = min(a_center.z + a.box_extents.z, b_center.z + b.box_extents.z)
	var maxPointZ = max(a_center.z - a.box_extents.z, b_center.z - b.box_extents.z)
	var median_x = (minPointX + maxPointX) / 2
	var median_y = (minPointY + maxPointY) / 2
	var median_z = (minPointZ + maxPointZ) / 2
	return Vector3i(median_x, median_y, median_z)
