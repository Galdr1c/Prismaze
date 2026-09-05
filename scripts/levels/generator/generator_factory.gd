class_name GeneratorFactory
extends RefCounted

const V1 = preload("res://scripts/levels/generator/generator_v1.gd")

# Design 6.7: published generator versions are frozen. Only the versions
# whose levels are still in the game stay servable.
func create(version: int) -> RefCounted:
	if version == 1:
		return V1.new()
	return null