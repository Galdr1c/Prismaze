class_name GameObjectState
extends RefCounted

enum Kind { SOURCE, MIRROR, PRISM, TARGET, WALL }

var id: String
var kind: int
var position: RefCounted
var orientation: int
var rotatable: bool
var color: int


func _init(object_id: String, object_kind: int, cell: RefCounted, angle: int = 0, can_rotate: bool = false, light_mask: int = 7) -> void:
	id = object_id
	kind = object_kind
	position = cell
	orientation = posmod(angle, 4)
	rotatable = can_rotate
	color = light_mask
