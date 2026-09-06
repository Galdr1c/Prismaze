class_name LightColor
extends RefCounted

const NONE: int = 0
const RED: int = 1
const GREEN: int = 2
const YELLOW: int = RED | GREEN
const BLUE: int = 4
const PURPLE: int = RED | BLUE
const CYAN: int = GREEN | BLUE
const WHITE: int = RED | GREEN | BLUE


func mix(left: int, right: int) -> int:
	return left | right


func satisfies(current_mask: int, required_mask: int) -> bool:
	return current_mask == required_mask
